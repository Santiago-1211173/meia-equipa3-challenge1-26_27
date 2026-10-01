# Drools Inference Engine Microservice (`drools_engine`)

A high-performance, containerized rule-based inference engine powered by **Java 21**, **Spring Boot 3**, and **Apache KIE Drools 8+**. This microservice acts as an expert system reasoning engine for evaluating clinical haemorrhage diagnosis scenarios, exposing an intuitive REST API designed to integrate with central orchestrators.

---

## 1. Domain Context & Rule Base (Haemorrhage)

The business logic is modeled directly from the clinical expert rules specified in the `Haemorrhage` knowledge base.

### 1.1 Decision Hierarchy
1. **Category Classification**:
   - `bloodEar == "yes"` $\rightarrow$ Hypothesis: **Upper type** haemorrhage
   - `bloodEar == "no"` $\rightarrow$ Hypothesis: **Lower type** haemorrhage

2. **Upper Type Haemorrhage Diagnostics**:
   - `Hypothesis("upper type")` $\wedge$ `earAche == "yes"` $\rightarrow$ **Otorrhagia**
   - `Hypothesis("upper type")` $\wedge$ `deafness == "yes"` $\rightarrow$ **Otorrhagia**
   - `Hypothesis("upper type")` $\wedge$ `cerebrospinal == "yes"` $\rightarrow$ **Skull fracture**

3. **Lower Type Haemorrhage Diagnostics**:
   - `Hypothesis("lower type")` $\wedge$ `bloodNose == "yes"` $\rightarrow$ **Epistaxe**
   - `Hypothesis("lower type")` $\wedge$ `bloodMouth == "yes"` $\wedge$ `bloodBrown == "yes"` $\wedge$ `vomiting == "yes"` $\rightarrow$ **Hemathese**
   - `Hypothesis("lower type")` $\wedge$ `bloodMouth == "yes"` $\wedge$ `bloodBrown == "no"` $\wedge$ `vomiting == "no"` $\rightarrow$ **Mouth haemorrhage**
   - `Hypothesis("lower type")` $\wedge$ `bloodVagina == "yes"` $\rightarrow$ **Metrorrhagia**
   - `Hypothesis("lower type")` $\wedge$ `bloodPenis == "yes"` $\rightarrow$ **Hematuria**
   - `Hypothesis("lower type")` $\wedge$ `bloodAnus == "yes"` $\wedge$ `bloodCoffee == "yes"` $\rightarrow$ **Melena**
   - `Hypothesis("lower type")` $\wedge$ `bloodAnus == "yes"` $\wedge$ `bloodCoffee == "no"` $\rightarrow$ **Rectal bleeding**

4. **Fallback / Unknown**:
   - If no specific diagnosis rule fires $\rightarrow$ **"Look for the the doctor!"**

---

## 2. Architecture & Quality Principles

- **Separation of Concerns (SOLID)**: Layered architecture separating controllers, services, configuration, domain models (Drools facts), and API data transfer objects (DTOs).
- **Isolation**: Domain facts (`Evidences`, `Hypothesis`, `Conclusion`) are decoupled from external request/response models (`EvidencesRequestDto`, `EvaluationResponseDto`).
- **Input Validation**: Strict Bean Validation rejecting invalid values and defaulting absent clinical variables safely to `"no"`.
- **Explainability**: Inference results return not only conclusions, but also derived hypotheses and the complete sequence of fired rules (`firedRules`).

---

## 3. REST API Specification

### 3.1 Health Check
- **Endpoint**: `GET /api/v1/inference/health`
- **Response** (`200 OK`):
```json
{
  "status": "UP",
  "service": "drools-engine",
  "version": "1.0.0",
  "activeKieBase": "haemorrhageKBase",
  "totalRules": 13,
  "timestamp": "2026-10-01T12:00:00Z"
}
```

### 3.2 Evaluate Clinical Evidences
- **Endpoint**: `POST /api/v1/inference/evaluate`
- **Request Headers**: `Content-Type: application/json`
- **Request Body Example**:
```json
{
  "bloodEar": "yes",
  "earAche": "yes"
}
```
- **Response** (`200 OK`):
```json
{
  "status": "SUCCESS",
  "primaryDiagnosis": "Otorrhagia",
  "conclusions": [
    "Otorrhagia"
  ],
  "hypothesis": "upper type",
  "firedRules": [
    "r1_upper_type_classification",
    "r3_otorrhagia_ear_ache"
  ],
  "timestamp": "2026-10-01T12:00:01Z",
  "evidencesEvaluated": {
    "bloodEar": "yes",
    "earAche": "yes"
  }
}
```

---

## 4. Docker & Lifecycle Management

Since local Java/Maven installations are not required, everything is containerized.

### 4.1 Build Docker Image
```bash
docker build -t drools-engine:latest ./drools_engine
```

### 4.2 Run Microservice Container
```bash
docker run -d --name drools-engine -p 8080:8080 drools-engine:latest
```

### 4.3 Execute Healthcheck
```bash
curl http://localhost:8080/api/v1/inference/health
```

### 4.4 Run Evaluation Query
```bash
curl -X POST http://localhost:8080/api/v1/inference/evaluate \
  -H "Content-Type: application/json" \
  -d '{"bloodEar": "no", "bloodNose": "yes"}'
```
