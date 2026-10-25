"""Asynchronous HTTP client for communicating with the Levi's Drools Expert reasoning engine."""

from __future__ import annotations

from datetime import datetime, timezone
import time
from typing import Any, Dict, List, Optional, Union
from uuid import UUID

import httpx

from app.core.config import settings
from app.core.exceptions import (
    LevisConnectionError,
    LevisResponseError,
    LevisTimeoutError,
)

DEFAULT_COLABORADOR: Dict[str, Any] = {
    "id": "DEV-KH",
    "nome": "Key Holder",
    "funcao": "KEY_HOLDER",
    "aprovadoPeloDM": False,
    "idCredencialPOS": "POS-KH",
}


class LevisClient:
    """Asynchronous HTTP client for the Levi's Drools Expert system.

    Manages connection pooling, dev JWT authentication, cache renewal,
    serialization, timeout handling, and exception mapping for the
    Levi's returns reasoning microservice running on Spring Boot / Drools.
    """

    def __init__(
        self,
        base_url: Optional[str] = None,
        timeout: Optional[float] = None,
        client: Optional[httpx.AsyncClient] = None,
    ) -> None:
        """Initialize the Levi's client.

        Args:
            base_url: Base URL of the Levi's Drools service (defaults to settings.LEVIS_DROOLS_URL).
            timeout: Request timeout in seconds (defaults to settings.LEVIS_TIMEOUT_SECONDS).
            client: Optional pre-configured httpx.AsyncClient.
        """
        self.base_url = (base_url or settings.LEVIS_DROOLS_URL).rstrip("/")
        self.timeout = timeout if timeout is not None else settings.LEVIS_TIMEOUT_SECONDS
        self._external_client = client is not None
        self._client = client

        # Token caching state
        self._token: Optional[str] = None
        self._token_expires_at: Optional[float] = None

    def _get_client(self) -> httpx.AsyncClient:
        """Return the active AsyncClient or initialize an internally managed instance."""
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(
                base_url=self.base_url,
                timeout=self.timeout,
                headers={
                    "Content-Type": "application/json",
                    "Accept": "application/json",
                },
            )
            self._external_client = False
        return self._client

    async def close(self) -> None:
        """Close the internally managed HTTP client session if applicable."""
        if self._client is not None and not self._external_client and not self._client.is_closed:
            await self._client.aclose()
            self._client = None

    async def __aenter__(self) -> LevisClient:
        """Enter the async context manager."""
        self._get_client()
        return self

    async def __aexit__(self, exc_type: Any, exc_val: Any, exc_tb: Any) -> None:
        """Exit the async context manager and release client resources."""
        await self.close()

    async def _get_dev_token(
        self,
        force_refresh: bool = False,
        colaborador: Optional[Dict[str, Any]] = None,
    ) -> str:
        """Retrieve a development JWT token, using an in-memory cache with auto-renewal.

        Args:
            force_refresh: Force emission of a new token regardless of cache.
            colaborador: Optional collaborator profile to issue token for.

        Returns:
            The raw JWT Bearer token string.
        """
        now = time.time()
        if not force_refresh and self._token and self._token_expires_at:
            if now < (self._token_expires_at - 30.0):
                return self._token

        client = self._get_client()
        token_url = f"{self.base_url}/api/v1/dev/tokens"
        payload = colaborador or DEFAULT_COLABORADOR

        try:
            response = await client.post(
                token_url,
                json=payload,
                timeout=self.timeout,
            )
            response.raise_for_status()
            token_data = response.json()
            token = token_data.get("token") or token_data.get("tokenAcesso")
            if not token:
                raise LevisResponseError(
                    message="Failed to retrieve JWT token: empty token in response",
                    status_code=response.status_code,
                    response_data=token_data,
                )

            self._token = token
            expira_em_str = token_data.get("expiraEm")
            if expira_em_str:
                try:
                    exp_dt = datetime.fromisoformat(expira_em_str.replace("Z", "+00:00"))
                    self._token_expires_at = exp_dt.replace(tzinfo=timezone.utc).timestamp()
                except Exception:
                    self._token_expires_at = now + 3600.0
            else:
                self._token_expires_at = now + 3600.0

            return self._token

        except httpx.ConnectError as exc:
            raise LevisConnectionError(
                message=f"Could not connect to Levi's Drools engine at '{self.base_url}': {exc}",
                url=self.base_url,
            ) from exc
        except httpx.TimeoutException as exc:
            raise LevisTimeoutError(
                message=f"Levi's Drools engine timed out while obtaining dev token after {self.timeout}s: {exc}",
                timeout_seconds=self.timeout,
            ) from exc
        except httpx.HTTPStatusError as exc:
            raise LevisResponseError(
                message=f"Dev token generation failed with HTTP {exc.response.status_code}",
                status_code=exc.response.status_code,
                response_data=self._extract_error_data(exc.response),
            ) from exc
        except httpx.NetworkError as exc:
            raise LevisConnectionError(
                message=f"Network error while requesting dev token: {exc}",
                url=self.base_url,
            ) from exc

    def _extract_error_data(self, response: httpx.Response) -> Dict[str, Any]:
        """Extract structured problem data from error response."""
        try:
            data = response.json()
            return data if isinstance(data, dict) else {"raw": response.text}
        except Exception:
            return {"raw": response.text}

    def _clean_payload(self, payload: Union[Dict[str, Any], Any]) -> Dict[str, Any]:
        """Normalize and sanitize request payload for Drools engine compatibility.

        Strips client-side metadata and collaborator field since collaborator is identified
        via the authenticated JWT token (ADR 0003).
        """
        if hasattr(payload, "model_dump"):
            data = payload.model_dump(mode="json", exclude_none=True, by_alias=True)
        elif isinstance(payload, dict):
            # Unwrap scenario structure if whole scenario was passed
            if "pedido" in payload and isinstance(payload["pedido"], dict):
                data = dict(payload["pedido"])
                if "indicadoresFraude" in payload and "indicadoresFraude" not in data:
                    data["indicadoresFraude"] = payload["indicadoresFraude"]
            else:
                data = dict(payload)
        else:
            data = dict(payload)

        # Drools Spring Boot PedidoAvaliacaoRequest does not accept colaborador in body
        data.pop("colaborador", None)

        # Sanitize items for Drools DTO compatibility
        if "artigos" in data and isinstance(data["artigos"], list):
            clean_artigos = []
            for art in data["artigos"]:
                if isinstance(art, dict):
                    clean_art = dict(art)
                    est = clean_art.get("estado")
                    if isinstance(est, dict):
                        clean_est = dict(est)
                        # Ensure revendivel is at artigo level
                        if "revendivel" in clean_est and "revendivel" not in clean_art:
                            clean_art["revendivel"] = clean_est["revendivel"]
                        # Remove fields not present in record EstadoProdutoRequest
                        clean_est.pop("revendivel", None)
                        clean_est.pop("bainhaFeitaOuAlterada", None)
                        clean_est.pop("temDefeitoFabrico", None)
                        clean_art["estado"] = clean_est
                    clean_artigos.append(clean_art)
                else:
                    clean_artigos.append(art)
            data["artigos"] = clean_artigos

        return data

    async def _request(
        self,
        method: str,
        path: str,
        *,
        json_payload: Optional[Any] = None,
        params: Optional[Dict[str, Any]] = None,
        auth_required: bool = True,
        retry_on_401: bool = True,
        colaborador: Optional[Dict[str, Any]] = None,
    ) -> Any:
        """Execute an HTTP request with error translation and automatic token renewal."""
        client = self._get_client()
        url = f"{self.base_url}{path}"
        headers: Dict[str, str] = {}

        if auth_required:
            token = await self._get_dev_token(colaborador=colaborador)
            headers["Authorization"] = f"Bearer {token}"

        clean_params = None
        if params:
            clean_params = {k: v for k, v in params.items() if v is not None}

        try:
            response = await client.request(
                method=method.upper(),
                url=url,
                json=json_payload,
                params=clean_params,
                headers=headers,
                timeout=self.timeout,
            )

            # If token expired or unauthorized, invalidate cache and retry once
            if response.status_code == 401 and auth_required and retry_on_401:
                self._token = None
                self._token_expires_at = None
                new_token = await self._get_dev_token(force_refresh=True, colaborador=colaborador)
                headers["Authorization"] = f"Bearer {new_token}"
                response = await client.request(
                    method=method.upper(),
                    url=url,
                    json=json_payload,
                    params=clean_params,
                    headers=headers,
                    timeout=self.timeout,
                )

            response.raise_for_status()

            if response.status_code == 204 or not response.content:
                return {}

            return response.json()

        except httpx.ConnectError as exc:
            raise LevisConnectionError(
                message=f"Could not connect to Levi's Drools engine at '{self.base_url}': {exc}",
                url=self.base_url,
            ) from exc

        except httpx.TimeoutException as exc:
            raise LevisTimeoutError(
                message=f"Levi's Drools engine timed out after {self.timeout}s: {exc}",
                timeout_seconds=self.timeout,
            ) from exc

        except httpx.HTTPStatusError as exc:
            error_data = self._extract_error_data(exc.response)
            message = f"Levi's Drools engine returned HTTP {exc.response.status_code}"
            if isinstance(error_data, dict):
                if "detail" in error_data:
                    message = error_data["detail"]
                elif "message" in error_data:
                    message = error_data["message"]
                elif "title" in error_data:
                    message = error_data["title"]

            raise LevisResponseError(
                message=message,
                status_code=exc.response.status_code,
                response_data=error_data if isinstance(error_data, dict) else {},
            ) from exc

        except httpx.NetworkError as exc:
            raise LevisConnectionError(
                message=f"Network error while communicating with Levi's Drools engine: {exc}",
                url=self.base_url,
            ) from exc

    # =========================================================================
    # CORE REASONING & DECISION EVALUATION
    # =========================================================================

    async def evaluate(self, payload: Union[Dict[str, Any], Any]) -> Dict[str, Any]:
        """Submit return/exchange order facts to the Drools rule engine for diagnosis.

        Args:
            payload: Order facts as dictionary or Pydantic model.

        Returns:
            Dict containing the serialized DecisaoResponse.
        """
        request_data = self._clean_payload(payload)
        return await self._request("POST", "/api/v1/avaliacoes", json_payload=request_data)

    async def get_evaluation(self, evaluation_id: Union[str, UUID]) -> Dict[str, Any]:
        """Retrieve a persisted decision evaluation by its UUID.

        Args:
            evaluation_id: UUID of the evaluated return record.

        Returns:
            Dict containing DecisaoResponse.
        """
        return await self._request("GET", f"/api/v1/avaliacoes/{evaluation_id}")

    async def list_evaluations(
        self,
        loja: Optional[str] = None,
        pagina: int = 0,
        tamanho: int = 20,
    ) -> Dict[str, Any]:
        """Retrieve historical evaluations (most recent first).

        Args:
            loja: Optional store code filter.
            pagina: Zero-indexed page number.
            tamanho: Page size (1 to 100).

        Returns:
            Dict containing PaginaDto<AvaliacaoResumoResponse>.
        """
        params = {"pagina": pagina, "tamanho": tamanho}
        if loja:
            params["loja"] = loja
        return await self._request("GET", "/api/v1/avaliacoes", params=params)

    # =========================================================================
    # EXPLAINABILITY (MISSING DATA, WHY, HOW, WHY NOT, WHAT IF)
    # =========================================================================

    async def get_missing_data(
        self,
        payload: Union[Dict[str, Any], Any],
        locale: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Inspect incomplete evaluation order and return required pending inputs (O que falta?).

        Args:
            payload: Partially filled order facts.
            locale: Optional locale tag (e.g. 'pt-PT', 'en-US').

        Returns:
            Dict containing DadosEmFaltaResponse.
        """
        request_data = self._clean_payload(payload)
        params = {"locale": locale} if locale else None
        return await self._request(
            "POST",
            "/api/v1/avaliacoes/dados-em-falta",
            json_payload=request_data,
            params=params,
        )

    async def get_why(
        self,
        dado: str,
        payload: Union[Dict[str, Any], Any],
        locale: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Justify causal reason for requiring a specific input code (Porquê?).

        Args:
            dado: Code of the input fact (e.g. 'IN-010').
            payload: Current evaluation facts.
            locale: Optional locale tag.

        Returns:
            Dict containing ExplicacaoPorqueResponse.
        """
        request_data = self._clean_payload(payload)
        params: Dict[str, Any] = {"dado": dado}
        if locale:
            params["locale"] = locale
        return await self._request(
            "POST",
            "/api/v1/avaliacoes/porque",
            json_payload=request_data,
            params=params,
        )

    async def explain_how(
        self,
        evaluation_id: Union[str, UUID],
        conclusao: Optional[str] = None,
        artigo: Optional[str] = None,
        locale: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Return the explanation trace of triggered rules (Como?).

        Args:
            evaluation_id: Persisted evaluation UUID.
            conclusao: Optional target conclusion (e.g. 'OUT-001').
            artigo: Optional article ID for article-specific conclusions.
            locale: Optional locale tag.

        Returns:
            Dict containing ExplicacaoComoResponse or ExplicacaoConclusaoResponse.
        """
        params: Dict[str, Any] = {}
        if conclusao is not None:
            params["conclusao"] = conclusao
        if artigo is not None:
            params["artigo"] = artigo
        if locale is not None:
            params["locale"] = locale
        return await self._request(
            "GET",
            f"/api/v1/avaliacoes/{evaluation_id}/explicacoes/como",
            params=params,
        )

    async def explain_why_not(
        self,
        evaluation_id: Union[str, UUID],
        conclusao: Optional[str] = None,
        regra: Optional[str] = None,
        artigo: Optional[str] = None,
        locale: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Explain why a specific conclusion or rule did not fire (Porque não?).

        Args:
            evaluation_id: Persisted evaluation UUID.
            conclusao: Optional target conclusion (e.g. 'OUT-001:PERMITIR').
            regra: Optional rule ID (e.g. 'PT-003').
            artigo: Optional article ID.
            locale: Optional locale tag.

        Returns:
            Dict containing ExplicacaoPorqueNaoConclusaoResponse or ExplicacaoPorqueNaoResponse.
        """
        params: Dict[str, Any] = {}
        if conclusao is not None:
            params["conclusao"] = conclusao
        if regra is not None:
            params["regra"] = regra
        if artigo is not None:
            params["artigo"] = artigo
        if locale is not None:
            params["locale"] = locale

        return await self._request(
            "GET",
            f"/api/v1/avaliacoes/{evaluation_id}/explicacoes/porque-nao",
            params=params,
        )

    async def simulate(
        self,
        evaluation_id: Union[str, UUID],
        payload: Union[Dict[str, Any], Any],
        locale: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Simulate variations on an existing evaluation without modifying it (E se?).

        Args:
            evaluation_id: Persisted evaluation UUID.
            payload: SimulacaoRequest or dict with 'alteracoes'.
            locale: Optional locale tag.

        Returns:
            Dict containing SimulacaoResponse.
        """
        if hasattr(payload, "model_dump"):
            request_data = payload.model_dump(mode="json", exclude_none=True, by_alias=True)
        else:
            request_data = dict(payload)

        params = {"locale": locale} if locale else None
        return await self._request(
            "POST",
            f"/api/v1/avaliacoes/{evaluation_id}/simulacoes",
            json_payload=request_data,
            params=params,
        )

    # =========================================================================
    # KNOWLEDGE BASE RULES CATALOG
    # =========================================================================

    async def list_rules(self) -> List[Dict[str, Any]]:
        """Retrieve the catalog of expert rules available in the Drools knowledge base.

        Returns:
            List of rule summary dictionaries.
        """
        return await self._request("GET", "/api/v1/regras")

    async def get_rule_detail(self, code: str) -> Dict[str, Any]:
        """Retrieve complete details and DRL variants for a specific rule code.

        Args:
            code: Unique rule identifier (e.g. 'PT-003', 'PC-002').

        Returns:
            Dict containing RegraDetalheDto.
        """
        return await self._request("GET", f"/api/v1/regras/{code}")

    # =========================================================================
    # UNCERTAINTY LAYER
    # =========================================================================

    async def get_uncertainty_parameters(self) -> Dict[str, Any]:
        """Retrieve the uncertainty layer parameters in force (demonstrative values).

        Returns:
            Dict containing ParametrosIncertezaResponse.
        """
        return await self._request("GET", "/api/v1/incerteza/parametros")

    # =========================================================================
    # DEV COLLABORATORS & HEALTH
    # =========================================================================

    async def list_dev_collaborators(self) -> List[Dict[str, Any]]:
        """List predefined development collaborators for authentication simulation.

        Returns:
            List of ColaboradorDto dictionaries.
        """
        return await self._request("GET", "/api/v1/dev/colaboradores", auth_required=False)

    async def get_health(self) -> Dict[str, Any]:
        """Retrieve operational health metrics from Spring Boot Actuator.

        Returns:
            Dict containing actuator health status.
        """
        return await self._request("GET", "/actuator/health", auth_required=False)

    async def check_health(self) -> bool:
        """Perform a quick liveness check against the Levi's Drools engine.

        Returns:
            True if the engine responds with status 'UP', False otherwise.
        """
        try:
            health = await self.get_health()
            return health.get("status") == "UP"
        except Exception:
            return False
