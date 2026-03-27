# Схема базы данных (Lift_app)

Источник правды: модели в `src/models/` и миграции Alembic.

## Как смотреть диаграмму

- **GitHub / GitLab**: откройте этот файл в веб-интерфейсе — блок `mermaid` подсветится автоматически.
- **Редактор**: расширение «Markdown Preview Mermaid Support» (или встроенное превью, если есть).
- **Онлайн**: скопируйте блок `mermaid` на [mermaid.live](https://mermaid.live) для экспорта в PNG/SVG.

## Примечания

- Таблица `acts_fact_of_mechanic` в коде отключена, в миграциях отсутствует.
- `steps`, `sub_steps`, `area_of_responsibility` есть в БД, на них нет внешних ключей из других таблиц; шаги в `acts_bases` хранятся строкой `step_list`.
- Тип **String** в SQLAlchemy без длины → обычно VARCHAR/TEXT (зависит от СУБД).

## Ограничения (не FK)

| Таблица | Ограничение |
|---------|-------------|
| `universal_users` | UNIQUE (`email`, `is_actual`) |
| `factories_models` | UNIQUE (`type_object_id`, `factory`, `model`) |
| `acts_bases` | UNIQUE (`factory_model_id`, `type_act_id`) |
| `objects` | UNIQUE (`factory_number`), UNIQUE (`registration_number`), UNIQUE (`factory_number`, `registration_number`) |
| `planned_to` | UNIQUE (`year`, `object_id`) |

---

```mermaid
erDiagram
    locations ||--o{ company : "location_id SET NULL"
    locations ||--o{ universal_users : "location_id SET NULL"

    roles ||--o{ universal_users : "role_id SET NULL"
    working_specialty ||--o{ universal_users : "working_specialty_id SET NULL"
    divisions ||--o{ universal_users : "division_id SET NULL"
    company ||--o{ universal_users : "company_id SET NULL"

    company ||--o{ contact_persons : "company_id SET NULL"
    company ||--o{ contracts : "company_id SET NULL"
    types_contracts ||--o{ contracts : "type_contract_id SET NULL"
    cost_types ||--o{ contracts : "cost_type_id SET NULL"

    type_objects ||--o{ factories_models : "type_object_id SET NULL"
    factories_models ||--o{ acts_bases : "factory_model_id SET NULL"
    types_acts ||--o{ acts_bases : "type_act_id SET NULL"

    universal_users ||--o{ organizations : "director_id SET NULL"

    organizations ||--o{ objects : "organization_id SET NULL"
    divisions ||--o{ objects : "division_id SET NULL"
    factories_models ||--o{ objects : "factory_model_id SET NULL"
    company ||--o{ objects : "company_id SET NULL"
    contact_persons ||--o{ objects : "contact_person_id SET NULL"
    contracts ||--o{ objects : "contract_id SET NULL"
    universal_users ||--o{ objects : "foreman_id SET NULL"
    universal_users ||--o{ objects : "mechanic_id SET NULL"

    objects ||--o{ acts_fact : "object_id SET NULL"
    acts_bases ||--o{ acts_fact : "act_base_id SET NULL"
    universal_users ||--o{ acts_fact : "foreman_id SET NULL"
    universal_users ||--o{ acts_fact : "main_mechanic_id SET NULL"
    statuses ||--o{ acts_fact : "status_id CASCADE"

    objects ||--o{ "order" : "object_id SET NULL"
    universal_users ||--o{ "order" : "creator_id SET NULL"
    universal_users ||--o{ "order" : "executor_id SET NULL"
    fault_category ||--o{ "order" : "fault_category_id SET NULL"
    reason_fault ||--o{ "order" : "reason_fault_id SET NULL"
    statuses ||--o{ "order" : "status_id CASCADE"

    "order" ||--o| order_photo : "order_id SET NULL"

    objects ||--o{ planned_to : "object_id SET NULL"
    acts_fact ||--o{ planned_to : "january..december _to_id SET NULL"

    locations {
        int id PK
        string name UK
    }
    roles {
        int id PK "no autoincrement"
        string name UK
    }
    working_specialty {
        int id PK
        string name UK
    }
    divisions {
        int id PK
        string title UK
        string photo
        bool is_actual
    }
    type_objects {
        int id PK "no autoincrement"
        string name UK
    }
    types_acts {
        int id PK "no autoincrement"
        string name UK
    }
    types_contracts {
        int id PK "no autoincrement"
        string name UK
    }
    cost_types {
        int id PK "no autoincrement"
        string name UK
    }
    statuses {
        int id PK "no autoincrement"
        string name UK
    }
    fault_category {
        int id PK
        string name UK
    }
    reason_fault {
        int id PK
        string name UK
    }
    steps {
        int id PK
        string name UK
    }
    sub_steps {
        int id PK
        string name UK
    }
    area_of_responsibility {
        int id PK
        string name UK
    }
    company {
        int id PK
        string name
        string director_name
        string cont_phone
        string email
        string cont_address
        string photo
        int location_id FK
        string site
        bool is_actual
    }
    factories_models {
        int id PK
        int type_object_id FK
        string factory
        string model
    }
    acts_bases {
        int id PK
        int factory_model_id FK
        int type_act_id FK
        string step_list
    }
    contact_persons {
        int id PK
        string name
        int company_id FK
        string phone UK "NOT NULL"
        string email
        string address
        string photo
        bool is_actual
    }
    contracts {
        int id PK
        int company_id FK
        string title UK
        date validity_period
        int type_contract_id FK
        int cost_type_id FK
        string file
        bool is_actual
    }
    universal_users {
        int id PK
        string name
        string email
        string password
        string contact_phone
        date birthday
        string photo
        int location_id FK
        int role_id FK
        int working_specialty_id FK
        string identity_card
        int division_id FK
        int company_id FK
        string qualification_file
        date date_of_employment
        bool is_actual
    }
    organizations {
        int id PK
        string title UK
        int director_id FK
        string phone_office
        string phone_dispatcher
        string phone_accountant
        string photo
        string site
        string email
        string address
        bool is_actual
    }
    objects {
        int id PK
        string name
        int organization_id FK
        int division_id FK
        string address
        int factory_model_id FK
        string factory_number UK
        string registration_number UK
        int number_of_stops
        int lifting_heights
        int load_capacity
        int width
        int cost_nds
        int cost_no_nds
        int company_id FK
        int contact_person_id FK
        int contract_id FK
        date date_inspection
        date planned_inspection
        date period_inspection
        int foreman_id FK
        int mechanic_id FK
        string letter_of_appointment
        string acceptance_certificate
        string act_pto
        string geo
        bool is_actual
    }
    acts_fact {
        int id PK
        int object_id FK
        int act_base_id FK
        string step_list_fact
        datetime created_at
        datetime started_at
        datetime finished_at
        int foreman_id FK
        int main_mechanic_id FK
        string file
        int status_id FK
    }
    order {
        int id PK
        int object_id FK
        int creator_id FK
        int fault_category_id FK
        string task_text
        int executor_id FK
        string commentary
        int reason_fault_id FK
        datetime created_at
        datetime accepted_at
        datetime in_progress_at
        datetime done_at
        int status_id FK
        bool is_viewed
    }
    order_photo {
        int id PK
        int order_id FK
        string photo
    }
    planned_to {
        int id PK
        string year
        int object_id FK
        int january_to_id FK
        int february_to_id FK
        int march_to_id FK
        int april_to_id FK
        int may_to_id FK
        int june_to_id FK
        int july_to_id FK
        int august_to_id FK
        int september_to_id FK
        int october_to_id FK
        int november_to_id FK
        int december_to_id FK
    }
```
