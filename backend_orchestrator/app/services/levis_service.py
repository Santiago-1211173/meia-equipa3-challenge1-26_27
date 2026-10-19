"""Service layer coordinating with the Levi's Drools Expert rule engine."""

from __future__ import annotations

import glob
import json
import logging
from pathlib import Path
import time
from typing import Any, Dict, List, Optional, Union
from uuid import UUID

from app.clients.levis_client import LevisClient
from app.core.config import BASE_DIR
from app.schemas.levis import (
    AvaliacaoResumoResponse,
    CenarioExemploResponse,
    ColaboradorDto,
    DadosEmFaltaResponse,
    DecisaoResponse,
    ExplicacaoComoResponse,
    ExplicacaoConclusaoResponse,
    ExplicacaoPorqueNaoConclusaoResponse,
    ExplicacaoPorqueNaoResponse,
    ExplicacaoPorqueResponse,
    PaginaResponse,
    PedidoAvaliacaoRequest,
    RegraDetalheDto,
    RegraResumoDto,
    SimulacaoRequest,
    SimulacaoResponse,
)

logger = logging.getLogger(__name__)

# Search candidates for Levi's scenario files
LOCAL_DATA_SCENARIOS_DIR = Path(__file__).resolve().parent.parent / "data" / "cenarios"
REPO_TEST_SCENARIOS_DIR = (
    BASE_DIR.parent
    / "drools-engine-levis-devolucoes-java"
    / "backend"
    / "pericial-rules"
    / "src"
    / "test"
    / "resources"
    / "cenarios"
)
DEFAULT_SCENARIOS_DIR = (
    LOCAL_DATA_SCENARIOS_DIR
    if LOCAL_DATA_SCENARIOS_DIR.exists() and any(LOCAL_DATA_SCENARIOS_DIR.glob("cenario-*.json"))
    else REPO_TEST_SCENARIOS_DIR
)


class LevisService:
    """Decoupled service handling validation, delegation, and formatting for Levi's returns logic.

    Enforces the 'Regra de Ouro': never implements business policies in Python,
    delegating all decision inference and explainability reasoning to Drools.
    """

    def __init__(
        self,
        levis_client: Optional[LevisClient] = None,
        scenarios_dir: Optional[Path] = None,
    ) -> None:
        """Initialize LevisService with injected client and scenario resources.

        Args:
            levis_client: Optional LevisClient instance (defaults to a new client).
            scenarios_dir: Optional directory path pointing to the 10 reference scenarios.
        """
        self.levis_client = levis_client or LevisClient()
        self.scenarios_dir = scenarios_dir or DEFAULT_SCENARIOS_DIR

    # =========================================================================
    # CORE EVALUATION
    # =========================================================================

    async def evaluate(
        self,
        request: Union[PedidoAvaliacaoRequest, Dict[str, Any]],
    ) -> DecisaoResponse:
        """Evaluate a return/exchange request and return the full expert diagnosis.

        Args:
            request: Validated PedidoAvaliacaoRequest or dictionary payload.

        Returns:
            Structured DecisaoResponse with eligibility, refund amounts, and rule trace.
        """
        start_t = time.perf_counter()
        raw_result = await self.levis_client.evaluate(request)
        duracao_ms = max(1, int((time.perf_counter() - start_t) * 1000))
        decisao = DecisaoResponse.model_validate(raw_result)

        # Persist Drools inference record asynchronously and safely
        try:
            from app.services.inferences_service import InferencesService
            await InferencesService.record_inference_safely(
                motor="DROOLS",
                decisao=decisao,
                pedido_data=request,
                duracao_ms=duracao_ms,
            )
        except Exception as exc:
            logger.warning("[LevisService] Could not persist Drools inference record: %s", exc)

        return decisao

    async def get_evaluation(
        self,
        evaluation_id: Union[str, UUID],
    ) -> DecisaoResponse:
        """Retrieve a persisted decision evaluation by UUID.

        Args:
            evaluation_id: Evaluation record UUID.

        Returns:
            Structured DecisaoResponse.
        """
        raw_result = await self.levis_client.get_evaluation(evaluation_id)
        return DecisaoResponse.model_validate(raw_result)

    async def list_evaluations(
        self,
        loja: Optional[str] = None,
        pagina: int = 0,
        tamanho: int = 20,
    ) -> PaginaResponse[AvaliacaoResumoResponse]:
        """Query evaluation history (management view).

        Args:
            loja: Optional store filter code.
            pagina: Page index (0-indexed).
            tamanho: Page size.

        Returns:
            Paginated evaluation summaries.
        """
        raw_page = await self.levis_client.list_evaluations(loja=loja, pagina=pagina, tamanho=tamanho)
        return PaginaResponse[AvaliacaoResumoResponse].model_validate(raw_page)

    # =========================================================================
    # EXPLAINABILITY (MISSING DATA, WHY, HOW, WHY NOT, WHAT IF)
    # =========================================================================

    async def get_missing_data(
        self,
        request: Union[PedidoAvaliacaoRequest, Dict[str, Any]],
        locale: Optional[str] = None,
    ) -> DadosEmFaltaResponse:
        """Identify missing inputs and their justifications for an incomplete order (O que falta?).

        Args:
            request: Incomplete order facts.
            locale: Optional locale tag.

        Returns:
            DadosEmFaltaResponse containing list of missing inputs.
        """
        raw_result = await self.levis_client.get_missing_data(request, locale=locale)
        return DadosEmFaltaResponse.model_validate(raw_result)

    async def get_why(
        self,
        dado: str,
        request: Union[PedidoAvaliacaoRequest, Dict[str, Any]],
        locale: Optional[str] = None,
    ) -> ExplicacaoPorqueResponse:
        """Explain why a specific input fact is demanded by the rules (Porquê?).

        Args:
            dado: Input fact code (e.g. 'IN-010').
            request: Current order facts.
            locale: Optional locale tag.

        Returns:
            ExplicacaoPorqueResponse containing question justification.
        """
        dado_limpo = (dado or "").strip().upper()
        # Drools organizes exchange type under IN-005 (PEDIDO); map EP-001 transparently
        dado_drools = "IN-005" if dado_limpo == "EP-001" else dado_limpo
        raw_result = await self.levis_client.get_why(dado_drools, request, locale=locale)
        if dado_limpo == "EP-001" and isinstance(raw_result, dict):
            raw_result["codigo"] = "EP-001"
            raw_result["dado"] = "EP-001"
            raw_result["pergunta"] = "A troca solicitada é apenas de tamanho para o mesmo modelo e cor?"
            if "EP-001" not in raw_result.get("regrasQueDependem", []):
                raw_result.setdefault("regrasQueDependem", []).insert(0, "EP-001")
        return ExplicacaoPorqueResponse.model_validate(raw_result)

    async def explain_how(
        self,
        evaluation_id: Union[str, UUID],
        conclusao: Optional[str] = None,
        artigo: Optional[str] = None,
        locale: Optional[str] = None,
    ) -> Union[ExplicacaoComoResponse, ExplicacaoConclusaoResponse]:
        """Explain how the decision (or a specific output conclusion) was deduced (Como?).

        Args:
            evaluation_id: Evaluation record UUID.
            conclusao: Optional target output conclusion code (e.g. 'OUT-001').
            artigo: Optional article ID.
            locale: Optional locale tag.

        Returns:
            ExplicacaoComoResponse (for full path) or ExplicacaoConclusaoResponse (for single conclusion).
        """
        raw_result = await self.levis_client.explain_how(
            evaluation_id=evaluation_id,
            conclusao=conclusao,
            artigo=artigo,
            locale=locale,
        )
        if conclusao is None:
            return ExplicacaoComoResponse.model_validate(raw_result)
        return ExplicacaoConclusaoResponse.model_validate(raw_result)

    async def explain_why_not(
        self,
        evaluation_id: Union[str, UUID],
        conclusao: Optional[str] = None,
        regra: Optional[str] = None,
        artigo: Optional[str] = None,
        locale: Optional[str] = None,
    ) -> Union[ExplicacaoPorqueNaoResponse, ExplicacaoPorqueNaoConclusaoResponse]:
        """Explain why a conclusion was not reached or a rule did not fire (Porque não?).

        Args:
            evaluation_id: Evaluation record UUID.
            conclusao: Optional target conclusion (e.g. 'OUT-001:PERMITIR').
            regra: Optional rule ID (e.g. 'PT-003').
            artigo: Optional article ID.
            locale: Optional locale tag.

        Returns:
            ExplicacaoPorqueNaoConclusaoResponse (for target conclusion) or ExplicacaoPorqueNaoResponse (for rule).
        """
        raw_result = await self.levis_client.explain_why_not(
            evaluation_id=evaluation_id,
            conclusao=conclusao,
            regra=regra,
            artigo=artigo,
            locale=locale,
        )
        if conclusao is not None:
            return ExplicacaoPorqueNaoConclusaoResponse.model_validate(raw_result)
        return ExplicacaoPorqueNaoResponse.model_validate(raw_result)

    async def simulate(
        self,
        evaluation_id: Union[str, UUID],
        request: Union[SimulacaoRequest, Dict[str, Any]],
        locale: Optional[str] = None,
    ) -> SimulacaoResponse:
        """Run 'What if' hypothetical counterfactual simulation on an existing evaluation (E se?).

        Args:
            evaluation_id: Evaluation record UUID.
            request: SimulacaoRequest or dict with 'alteracoes'.
            locale: Optional locale tag.

        Returns:
            SimulacaoResponse detailing rule diffs and simulated decision.
        """
        raw_result = await self.levis_client.simulate(
            evaluation_id=evaluation_id,
            payload=request,
            locale=locale,
        )
        return SimulacaoResponse.model_validate(raw_result)

    # =========================================================================
    # KNOWLEDGE BASE RULES CATALOG
    # =========================================================================

    async def list_rules(self) -> List[RegraResumoDto]:
        """List active business rules present in the Drools knowledge base.

        Returns:
            List of RegraResumoDto entries.
        """
        raw_list = await self.levis_client.list_rules()
        return [RegraResumoDto.model_validate(item) for item in raw_list]

    async def get_rule_detail(self, code: str) -> RegraDetalheDto:
        """Retrieve exhaustive details and DRL production variants for a specific rule.

        Args:
            code: Rule code (e.g. 'PT-003').

        Returns:
            RegraDetalheDto.
        """
        raw_detail = await self.levis_client.get_rule_detail(code)
        return RegraDetalheDto.model_validate(raw_detail)

    # =========================================================================
    # DEV COLLABORATORS & SCENARIOS
    # =========================================================================

    async def list_dev_collaborators(self) -> List[ColaboradorDto]:
        """List development store collaborators available for testing.

        Returns:
            List of ColaboradorDto items.
        """
        raw_list = await self.levis_client.list_dev_collaborators()
        return [ColaboradorDto.model_validate(item) for item in raw_list]

    def get_example_scenarios(self) -> List[CenarioExemploResponse]:
        """Load and return all 10 official Levi's expert test scenarios from repository resources.

        Returns:
            List of CenarioExemploResponse models sorted by scenario id.
        """
        scenarios: List[CenarioExemploResponse] = []
        pattern = str(self.scenarios_dir / "cenario-*.json")
        scenario_files = sorted(glob.glob(pattern))

        if not scenario_files and LOCAL_DATA_SCENARIOS_DIR.exists():
            scenario_files = sorted(glob.glob(str(LOCAL_DATA_SCENARIOS_DIR / "cenario-*.json")))

        if not scenario_files:
            logger.warning("No Levi's scenario files found in path '%s'", self.scenarios_dir)
            return scenarios

        for file_path in scenario_files:
            try:
                with open(file_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    scenarios.append(CenarioExemploResponse.model_validate(data))
            except Exception as exc:
                logger.error("Failed to parse scenario file '%s': %s", file_path, exc)

        scenarios.sort(key=lambda s: s.id)
        return scenarios

    def get_example_scenario_by_id(self, scenario_id: int) -> Optional[CenarioExemploResponse]:
        """Fetch a specific official Levi's scenario by its ordinal ID (1-10).

        Args:
            scenario_id: Integer identifier of the scenario.

        Returns:
            CenarioExemploResponse or None if not found.
        """
        for sc in self.get_example_scenarios():
            if sc.id == scenario_id:
                return sc
        return None

    # =========================================================================
    # HEALTH CHECK
    # =========================================================================

    async def get_health(self) -> Dict[str, Any]:
        """Check Drools engine operational status."""
        return await self.levis_client.get_health()

    async def check_health(self) -> bool:
        """Check if Levi's Drools engine is healthy."""
        return await self.levis_client.check_health()
