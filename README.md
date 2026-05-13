# README

## Web Contact Intake Endpoint

`POST /api/v1/contact` accepts JSON contact submissions from the marketing site.

**Payload shape:**
```json
{
  "contact": {
    "name": "Ana García",
    "email": "ana@example.com",
    "company": "Acme S.A.",
    "message": "Quisiera info sobre fechas...",
    "context": "https://kleer.la/cursos/scrum"
  }
}
```

**Contract:** On a well-formed payload (non-blank `name`, `email`, `message`), the endpoint returns `202 Accepted` and enqueues an `IngestWebContactJob`. Record creation, validation, and fuzzy matching happen asynchronously via Solid Queue. Failures (email collisions, validation errors) surface as retries and ultimately in the Solid Queue failed-job dashboard.

**Intake user:** All auto-created Prospects and Proposals are owned by the Intake user (`info@kleer.la`, role: `consultant`), provisioned by the `EnsureIntakeUserExists` data migration.

Things you may want to cover:

* Ruby version

Usualmente la última versión disponible

* Configuration

Necesitarás de otro desarrollador el archivo .env completo, no está en el repositorio.

* Database creation and initialization


* How to run the test suite

Dos opciones, la primera corre los test unitarios y más livianos, la segunda corre todos los
tests disponibles (seguridad, auditorías, análisis de código, etc)

```bash
1. rails test
1. bin/ci
```

* Services (job queues, cache servers, search engines, etc.)

Para iniciar la aplicación:

```bash
bin/dev
```

* Deployment instructions

Hay dos opc

```bash
# Entorno de QA
kamal deploy -d qa

# Entorno de produccion
kamal deploy
```
