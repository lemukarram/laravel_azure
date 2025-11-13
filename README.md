<div align="center">

# 🚀 Deploying Laravel to Azure with GitHub Actions & Docker

A complete, step-by-step guide and source code for setting up a full CI/CD pipeline to automatically deploy a Laravel application to Microsoft Azure.

</div>

-----

This repository contains the source code for the "Tech with muk" tutorial on deploying a Laravel application to **Microsoft Azure** using **Docker** and **GitHub Actions**.

This project demonstrates how to set up a full CI/CD (Continuous Integration/Continuous Deployment) pipeline. With this configuration, any new commit pushed to the `main` branch will automatically be built, containerized, and deployed to your Azure App Service, ensuring your live application is always up-to-date.

### 📺 Related YouTube Tutorial

This repository is the companion code for the full video tutorial on the "Tech with muk" YouTube channel.

**[➡️ Watch the full step-by-step video tutorial here\!](https://youtu.be/Zx2aP7DWEmM?si=wJuszvGQJiKrKp8R)**

-----

### ✨ Key Features

  * **Continuous Deployment:** Automatically deploy on every `git push` to the `main` branch.
  * **Containerized:** Uses Docker for a consistent, isolated, and scalable environment.
  * **Secure:** Uses GitHub Secrets to safely store and use Azure credentials.
  * **Efficient:** Leverages a multi-stage `Dockerfile` to create a lean, production-ready image.
  * **Modern:** Combines four powerful technologies: Laravel, Docker, Azure, and GitHub Actions.

### 🛠️ Technology Stack

  * **Framework:** [Laravel](https://laravel.com/)
  * **Cloud Platform:** [Microsoft Azure](https://azure.microsoft.com/)
      * Azure App Service
      * Azure Container Registry (ACR)
      * Azure Database for MySQL (Flexible Server)
  * **CI/CD:** [GitHub Actions](https://github.com/features/actions)
  * **Containerization:** [Docker](https://www.docker.com/)

-----

## Workflow Overview

Here is the simple, high-level flow of the CI/CD pipeline:

1.  **💻 Push to GitHub:** A developer pushes a new commit to the `main` branch.
2.  **🤖 Trigger GitHub Action:** The push automatically triggers the workflow defined in `.github/workflows/main.yml`.
3.  **🔧 Build & Push Docker Image:** The workflow builds a new Docker image of the Laravel app.
4.  **🔒 Login to Azure:** The action securely logs into your Azure Container Registry (ACR).
5.  **⬆️ Push to ACR:** The newly built Docker image is tagged and pushed to your private ACR.
6.  **🚀 Deploy to App Service:** The workflow notifies your Azure App Service to pull and run the new image, completing the deployment.

-----

## 📋 Prerequisites

Before you begin, make sure you have the following:

  * A **Microsoft Azure Account** with an active subscription.
  * A **GitHub Account**.
  * **Azure CLI** installed on your local machine.
  * **Docker Desktop** installed on your local machine (for building/testing locally).

-----

## 🚀 Step-by-Step Setup Guide

Follow these steps to replicate this deployment for your own project.

### 1\. Set Up Microsoft Azure Resources

First, we need to create the services on Azure that will host our application.

1.  **Create a Resource Group:** This will hold all our related services.

      * *Name (Example):* `laravel-azure-rg`

2.  **Create an Azure Container Registry (ACR):** This is where we will store our private Docker images.

      * *Name:* `laravelazure01`
      * *SKU:* `Basic`
      * After creation, go to **Access keys** and **Enable** the `Admin user`. We will need these credentials later.

3.  **Create a MySQL Flexible Server:** This will be our database.

      * *Name:* `laravelazure01`
      * Set up your admin username and password.
      * Go to **Networking** and ensure "Allow public access from any Azure service" is enabled.

4.  **Create an App Service:** This is the service that will run our application.

      * *Name:* `laravelazure01`
      * **Publish:** Select `Docker Container`
      * **Operating System:** Select `Linux`
      * **App Service Plan:** Create a new plan (e.g., `B1` or `S1` tier).
      * **Docker Tab:**
          * **Image Source:** `Azure Container Registry`
          * **Registry:** Select the ACR you just created (`laravelazure01`).
          * **Image:** `laravel-app` (This is the name we'll give our image in the workflow).
          * **Tag:** `latest`

5.  **Add Configuration (Environment Variables):**

      * In your `laravelazure01` App Service, go to **Configuration** \> **Application settings**.
      * Add all your Laravel `.env` variables here. Get the `DB_HOST`, `DB_USERNAME`, and `DB_PASSWORD` from the MySQL server you created.
      * **Required Variables:**
          * `APP_KEY` (Generate one with `php artisan key:generate` and paste it)
          * `APP_ENV` = `production`
          * `APP_DEBUG` = `false`
          * `APP_URL` = `https://laravelazure01.azurewebsites.net`
          * `DB_CONNECTION` = `mysql`
          * `DB_HOST` = (Your MySQL server host)
          * `DB_PORT` = `3306`
          * `DB_DATABASE` = (Your database name)
          * `DB_USERNAME` = (Your MySQL admin username)
          * `DB_PASSWORD` = (Your MySQL admin password)
      * **Important:** Add a setting `WEBSITES_PORT` and set its value to `80`.

### 2\. Prepare Your GitHub Repository

1.  **Fork this Repository:** Fork this `lemukarram/laravel_azure` repository to your own GitHub account.
2.  **Review the files:**
      * `.github/workflows/main.yml`: This is the main GitHub Action workflow file.
      * `Dockerfile`: This file instructs Docker on how to build the container.
      * `default.conf`: This is the Nginx configuration that will be used inside the container.

### 3\. Configure GitHub Actions Secrets

We need to give GitHub Actions secure access to our Azure account. **Never** hard-code credentials\!

1.  **Generate Azure Credentials:**

      * Open your terminal and run the following command (with Azure CLI installed). Replace `{subscription-id}` and `{resource-group-name}` with your own.

    <!-- end list -->

    ```bash
    az ad sp create-for-rbac --name "myGitHubActions" --role contributor \
                           --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group-name} \
                           --json-auth
    ```

      * This command will output a large JSON object. **Copy this entire JSON object.**

2.  **Add Secrets to GitHub:**

      * In your forked GitHub repository, go to `Settings` \> `Secrets and variables` \> `Actions`.
      * Click `New repository secret` and add the following:

| Secret Name | Value |
| :--- | :--- |
| `AZURE_CREDENTIALS` | Paste the **entire JSON object** from the command above. |
| `ACR_LOGIN_SERVER` | `laravelazure01.azurecr.io` |
| `ACR_USERNAME` | `laravelazure01` |
| `ACR_PASSWORD` | The password (key 1 or 2) from your ACR's "Access keys". |
| `AZURE_APP_NAME` | `laravelazure01` |
| `DOCKER_IMAGE_NAME` | `laravel-app` |

### 4\. Deploy\!

You are all set\! The workflow is configured to run on every push to the `main` branch.

1.  Make any change to the code (e.g., update `routes/web.php`).
2.  Commit and push your changes:
    ```bash
    git add .
    git commit -m "My first automated deployment! 🚀"
    git push origin main
    ```
3.  Go to the **Actions** tab in your GitHub repository. You will see your workflow running.
4.  Once the workflow is complete, your application will be live on your Azure App Service URL.

-----

### 📄 License

This project is open-sourced under the [MIT License](https://www.google.com/search?q=LICENSE).

### 👋 Connect with Me

  * **Author:** Mukarram Hussain
  * **YouTube:** [Tech with muk](https://www.google.com/search?q=https://www.youtube.com/%40Techwithmuk)
  * **GitHub:** [@lemukarram](https://www.google.com/search?q=https://github.com/lemukarram)
