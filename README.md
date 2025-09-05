# Caravelo Project

<img src = "img/xyz.jpg"> 

## Table of Contents

- [Project Structure](#project-structure)
- [Setup Instructions](#setup-instructions)
  - [Prerequisites](#prerequisites)
  - [Environment Variables](#environment-variables)
  - [Initiate the Environment](#initiate-the-environment)
- [dbt](#dbt)

## Project Structure

- **caravelo_project (project-root)/**
    - **dbt_transformation/**   (This is where your dbt project lives)
    - **docs/**                 (dbt documentation output)
    - **img/**                  (Project images and diagrams)
    - **initial_setup/**        (AWS IAM, Snowflake setup scripts)
    - **part_1_2_3/**           (Analysis documentation)
    - **.env**                  (Environment variables - ignored by git)
    - **.gitignore**
    - **requirements.txt**
    - **README.md**

## Setup Instructions

### Prerequisites

Make sure you have the following installed on your local development environment:

* [.venv - Virtual Environment](https://docs.python.org/3/library/venv.html)
  * cd your_repo_folder:
    * cd "C:\PATH_TO_YOUR_DBT_FOLDER"
  * python -m venv .venv           (This will create a virtual environment for the repo folder)
  * source .venv/Scripts/activate  (This will activate your virtual environment)
  * Install everything you need for your project from the `requirements.txt` file:
    * make sure to update pip, this is important to avoid conflicts: `python.exe -m pip install --upgrade pip`
    * `pip install --no-cache-dir -r requirements.txt`  (This will install things inside your virtual environment)
    * Check: pip list

* [dbt - profiles.yml - DBT_PROFILES_DIR - Connections](https://docs.getdbt.com/docs/core/connect-data-platform/connection-profiles#advanced-customizing-a-profile-directory)
  * When you invoke dbt from the command line (or from any terminal), dbt parses the `dbt_project.yml` file and obtains the 'profile name', which is where the connection credentials (the ones used to connect to your Data Warehouse) are defined. This 'profile name' is a parameter in the `dbt_project.yml` that makes reference for the any of the 'profiles' you created in the `profiles.yml` file.  
  * In order for dbt to test if the connections to databases are working, it needs to find the `profiles.yml`, which is usually located in `~/.dbt` folder.
  * However, since we have multiple dbt projects, it is better to put the `profiles.yml` file within a `.dbt` folder closer to our dbt projects so that it can be easier to manage.
  * Create a `DBT_PROFILES_DIR` environment variable in Windows:
    * Windows Flag on your Keyboard + R:
      * sysdm.cpl -> Advanced Tab -> Environment Variables
      * Create a `DBT_PROFILES_DIR` variable in the "User variables for YOUR_USER" part, and put the path to your `.dbt` folder from your repo folder.
        * Example: Set `DBT_PROFILES_DIR` to C:\Projeto_dbt
    * Close and Open your VSCode
    * Go the the Git Bash Terminal (or Powershell)
    * Check it by doing: echo $DBT_PROFILES_DIR
    * Go to your dbt project folder in your repo (C:\PATH_TO_DBT_FOLDER)
    * Do: dbt debug

Make sure to inclue a .gitignore file with the following information:

* .venv/         (to ignore the virtual environment stuff)
* *.pyc          (to ignore python bytecode files)
* .env           (to ignore sensitive information, such as database credentials)

### Environment Variables
The .gitignore file, ignores the `.env` file for security reasons. However, since this is just for educational purposes, follow the step below to include it in your project. If you do not include it, the docker will not work.

Create a `.env` file in the project root with the following content:

# Snowflake Connection Details
SNOWFLAKE_ACCOUNT=YOUR_ACCOUNT
SNOWFLAKE_USER=YOUR_USER
SNOWFLAKE_PASSWORD=YOUR_PASSWORD
SNOWFLAKE_ROLE=YOUR_ROLE
SNOWFLAKE_WAREHOUSE=YOUR_WAREHOUSE
SNOWFLAKE_DATABASE=YOUR_DATABASE

# Snowflake Schema Configuration
SNOWFLAKE_SCHEMA_RAW=raw
SNOWFLAKE_SCHEMA_STAGING=staging
SNOWFLAKE_SCHEMA_ANALYTICS=analytics

# S3 Configuration
S3_CSV_STAGE=YOUR_CSV_STAGE_NAME
S3_JSON_STAGE=YOUR_JSON_STAGE_NAME
S3_CSV_FILE_FORMAT=YOUR_CSV_FILE_FORMAT
S3_JSON_FILE_FORMAT=YOUR_JSON_FILE_FORMAT

# AWS Configuration (if needed)
S3_REGION=YOUR_REGION
S3_BUCKET_NAME=YOUR_BUCKET_NAME
S3_SNOWFLAKE_STORAGE_INTEGRATION=YOUR_STORAGE_INTEGRATION
S3_SNOWFLAKE_IAM_ROLE_ARN=arn:aws:iam::YOUR_ROLE:role/mysnowflakerole

If you want to check the environment variables from your current folder, do:
* printenv (this will show if the environmental variables were loaded within the Docker container)
* printenv | grep SNOWFLAKE (this functions as a filter to show only the variables that contain 'SNOWFLAKE')

### Initiate the Environment

1. **Clone the repository:**

   ```bash
   git clone YOUR_GIT_REPO_URL.git
   cd "C:\PATH_TO_DBT_FOLDER"

2. **Activate you Virtual Environment (.venv)**

* cd "C:\PATH_TO_DBT_FOLDER"
* source .venv/Scripts/activate

## dbt

* Go to the `dbt_transformation/` folder and operate dbt by following the `README` in there.
  * cd "C:\PATH_TO_DBT_FOLDER"
  * `dbt debug`