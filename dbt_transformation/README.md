# ETL - Leveraging dbt-Snowflake to perform Transformation Step (Reading Parquet from S3 -> Storing in Snowflake External Tables -> dbt Transformation in Snowflake).

## Table of Contents

- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [dbt](#dbt)
- [Transformation Step](#transformation-step)

## Project Structure

- **dbt_1_transformation (your-dbt-project)/**
    - **.devcontainer/**
      - devcontainer.json
    - **.dbt**
      - profiles.yml (connection details for our database environments)
    - **analyses**
    - **dbt_packages**
    - **logs** (ignored in git)
      - dbt.log
    - **macros**
      - **tests**
        - date_format.sql (macro to ensure date columns have date format)
      - generate_schema_name.sql (this macro makes sure your database schemas' names are respected)
    - **models**
      - **bronze**
        - snowflake_external_stage.yml (dbt source file creating external tables in Snowflake)
      - **silver**
        - silver_dbt_model_1.sql  (this represents the dim and facts tables)
        - properties_silver.sql
      - **gold**
        - gold_dbt_model_1.sql    (this represents the final aggregated tables for a Churn Prediction Model)
        - properties_gold.sql
    - **seeds**
    - **snapshots**
    - **target** (ignored in git)
    - **tests**
    - **.env**
    - **.gitignore**
    - **dbt_project.yml**    (the main file: this is how dbt knows a directory is a dbt project)
    - **packages.yml**       (where dbt packages should be configured)
    - **package-lock.yml**   (created by dbt when the 'dbt deps' is executed against the packages.yml)
    - **README.md**
    - snowflake_create_dbt_user_no_MFA.sql (a file to help with creating a role an user in Snowflake)
    - snowflake_s3_storage_integration_ext_stage.sql (a file to help with storage integration in Snowflake)

## Prerequisites

Make sure to inclue a .gitignore file with the following information:

*.pyc          (to ignore python bytecode files)
.env           (to ignore sensitive information, such as database credentials)
target/        (to ignore compiled SQL files and other build artifacts that are generated when dbt runs)
dbt_packages/  (to ignore where dbt installs packages, which are specific to your local environment)
logs/          (to ignore logs)
data/          (to ignore CSV files)

## dbt

dbt (Data Build Tool) is a development environment that enables data analysts and engineers to transform data in their warehouse more effectively. To use dbt in this project, follow these steps:

1. **Install dbt**
  * The Dockerfile and Docker Compose file will do this for you.
2. **Configure database connection**
  * The `profiles.yml` was created inside a `.dbt` folder in the same level as the `docker-compose.yml`. It defines connections to your data warehouse. It also uses environment variables to specify sensitive information like database credentials (which in this case is making reference to the `.env` file that is being ignored by `.gitignore`, so you should have one in the same level as the `docker-compose.yml` - as shown in the folder structure above.)
3. **Install dbt packages**
  * Never forget to run `dbt deps` before `dbt run` so that dbt can install the packages within the `packages.yml` file.

### Transformation Step

1) Ensure your project environment is ready by following the README at `C:\Projeto_dbt\dbt-snowflake\README.md`.

2) Ensure your **AWS** environment is ready.
  * You need to setup an AWS Account.
  * You need to create an S3 Bucket.
  * The bucket is: `YOUR_BUCKET`

3) Ensure your **Snowflake** environment is ready.
  * You need to setup an Snowflake Account.
  * In this project, we read from my S3 Bucket and write into Snowflake as External Tables. Then, we do the transformations in Snowflake, via dbt commands. 
  * The way we chose to do this is called Snowflake **Storage Integration**, which opens a secure connection between the Snowflake AWS Role and the AWS S3 Role.
  * The next step after `Storage Integration` is to create an `External Stage` in Snowflake.
    * **NOTE**: Whenever you create a new External Stage, you need to update the `ExternalID` policy of the AWS role, in the "Trusted entities" part.
  * Follow this (https://docs.snowflake.com/en/user-guide/data-load-s3-config-storage-integration) and it will guide you through the following:
    * Create an IAM Policy (done in AWS).
    * Create an IAM Role (done in AWS).
    * Storage Integration in Snowflake. Check: `snowflake_s3_storage_integration_ext_stage.sql`
        * Retrieve the AWS IAM User for your Snowflake Account.
        * Grant the IAM User Permissions to Access Bucket Objects.
        * Create an External Stage.
        * **Note**: 
          * The **External Tables** will be created by dbt, see below.

4) Ensure your `dbt` environment is ready.
  * Configure your `profiles.yml`.
    * The `profiles.yml` is now located at `C:\PATH_TO_PROFILES` (via DBT_PROFILES_DIR in the System Variables in Windows).
    * It defines connections to your data warehouses. It also uses environment variables to specify sensitive information like database credentials (which in this case is making reference to the `.env` file that is being ignored by `.gitignore` as shown in the README at at `C:\PATH_TO_DBT_FOLDER\README.md`).
    * This file contains the necessary information to use **Snowflake** as an adapter.
  * Organize your dbt project directory.
    * `dbt_project.yml` file:
        * Reference: https://docs.getdbt.com/reference/dbt_project.yml
        * This is how dbt knows a directory is a dbt project. It also contains important information that tells dbt how to operate your project.
        * It points to the profile you wnat to use frmo the list of profiles you can create in the `profiles.yml` file.
      * `packages.yml` file:
        * Reference: https://docs.getdbt.com/docs/build/packages#how-do-i-add-a-package-to-my-project
        * It was created by me and not by dbt. It is good to have to organize the dbt dependencies.
        * This file will specify the dependencies your project needs.
        * Make sure that the `dbt-utils` package is compatible with your `dbt-core` version (https://hub.getdbt.com/dbt-labs/dbt_utils/latest/)
        * Install dbt Packages:
          * `dbt clean`
            * This will clean all dependencies.and other things (https://docs.getdbt.com/reference/commands/clean).
          * then `dbt deps`
            * this will look for the `packages.yml` file that should be in the same level as `dbt_project.yml` (https://docs.getdbt.com/reference/commands/deps).
          * This file will specify the dependencies your project needs.
          * We used `dbt-utils` and `dbt_external_tables`
          * Make sure that the `dbt-utils` package is compatible with your `dbt-core` version (https://hub.getdbt.com/dbt-labs/dbt_utils/latest/)
    * `models/` folder: 
      * Contains the dbt models (i.e., SQL scripts or *.sql files with Jinja). The models can be located in folders or subfolders.
      * `models/flamengo/bronze/`: Here, we create a folder for each club and a subfolder `bronze/`. This subfolder will make reference to the bronze layer of a medalion architecture, where the raw data (the tables in production in Postgres that are used as source to the dim and facts) is stored.  
        * `models/bronze/snowflake_external_stage.yml`
          * This is the heart of the **External Tables**.
          * The `dbt run-operation stage_external_sources` command (see below) will look into this file, which creates the External Tables in Snowflake in the Bronze schema in Snowflake (*it already infers the schema from the JSON that is created in the VALUE column of each External Table*). 
          * When referencing these "source" external tables in the dbt models, make sure to use the `{{ source('source_name','table_name') }}` jinja. The Silver and Gold layer will make reference to the Bronze models by using another jinja, the `{{ ref('bronze_model_name') }}`.
          * Notice that the `source_name` is defined with the `name:` tag in the `snowflake_external_stage.yml` file.
      * `models/silver`: will contain the dbt models to be materialized as tables in the Silver schema in Snowflake.
      * `models/gold`: will contain the dbt models to be materialized as tables in the Gold schema in Snowflake.
    * `macro/` folder:
      * Examples:
          * `macro/tests/date_format.sql`: I created this macro in a `test/` folder to ensure that the date columns have a date format.
            * To apply this test, you need to put it in the `date_tests:` parameter of the `properties.yml`.
          * `macro/generate_schema_name.sql`: macro that makes sure that the name we chose for the schema (i.e., the `dbt_your_user` name) is the one being used when the schemas are created in Snowflake. 

4) Run dbt for the second dbt project (`dbt_transformation/`)
  * run: `C:\PATH_TO_DBT_FOLDER\dbt_transformation`
  * run: `dbt debug`   (this makes sure the database connection is working).
    * If you use MFA, it will be requested in your mobile phone. Accept it to continue!
  * run: `dbt clean`   (to clean all dependencia and start from scratch - only if you want)
  * run: `dbt deps`    (this will install the packages from the `packages.yml` file.)
  * We are using Snowflake External Tables as a way to make reference to Parquet files in S3. Therefore, we need to run the following before doing a `dbt run` so that dbt can create the External Tables in the **existing** External Stage:
    * run: `dbt run-operation stage_external_sources` (This will create the External Tables in Snowflake for all sources)
      * For example, if you want to specify a source: `dbt run-operation stage_external_sources --args "select: bronze.source_a"`
      * This get's the `name: bronze` and the `tables: -name: source_a`
      * from `models\bronze\snowflake_external_stage.yaml`
    * Check here: https://github.com/dbt-labs/dbt-external-tables/tree/0.9.0/?tab=readme-ov-file#syntax
    * An official example here: https://github.com/dbt-labs/dbt-external-tables/blob/main/sample_sources/snowflake.yml
  * run: `dbt run` and dbt will materialize the Parquet files into Snowflakes's Silver and Gold schema.