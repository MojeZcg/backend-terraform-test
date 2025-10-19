# Backend-Terraform-test

Proyecto de ejemplo para gestionar infraestructura con Terraform. Contiene configuraciones mínimas y buenas prácticas para iniciar despliegues en la nube (provider configurable).

## Contenido

- Ejemplo reutilizable de un backend hecho en python con infraestructura en Terraform.
- Estructura pensada para separar módulos, entornos y variables.

## Requisitos

- Credenciales del proveedor cloud configuradas (Amazon Cloud Services)
- Herramientas opcionales: psql, psycopg2 y sqlalchemy

## Estructura

- app/
  - Dockerfile
  - main.py
  - requirements.txt
- main.tf
- variables.tf
- output.tf

## Licencia

Este proyecto está licenciado bajo la Licencia MIT. Consulte el archivo [LICENCIA](./LICENSE) para obtener más información.
