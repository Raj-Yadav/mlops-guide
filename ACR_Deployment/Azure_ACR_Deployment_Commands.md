# Azure Container Registry (ACR) Deployment Quick Reference

**Purpose:** A quick reference guide to provision an Azure Container Registry via Terraform and push a local BentoML Docker image to it.

*Note: Ensure your Terraform configuration file (`main.tf`) is present in your working directory before running these commands.*

## 1. Infrastructure Provisioning (Terraform)

These commands use the `main.tf` file to create the necessary Azure resources and output your registry credentials.

* **Initialize Terraform:**
    ```bash
    terraform init
    ```
    *Explanation:* Initializes the working directory containing your `main.tf` file. It downloads the required Azure provider plugins.

* **Review Execution Plan (Optional but recommended):**
    ```bash
    terraform plan
    ```
    *Explanation:* Reads `main.tf` and displays a preview of the Azure resources (Resource Group and ACR) that will be created.

* **Apply Configuration:**
    ```bash
    terraform apply -auto-approve
    ```
    *Explanation:* Executes the plan defined in `main.tf` to actually create the resources in Azure. The `-auto-approve` flag skips the manual yes/no confirmation prompt.

* **Retrieve Sensitive Registry Password:**
    ```bash
    terraform output -raw registry_password
    ```
    *Explanation:* Extracts the generated ACR admin password from the Terraform state. You will need this, along with the `registry_login_server` and `registry_username` outputs displayed after the apply step, for the Docker login.

## 2. Image Tagging and Publishing (Docker)

These commands authenticate your local Docker client with Azure and push your specific image (`celestial-bodies-classifier:latest`).

* **Log in to Azure Container Registry:**
    ```bash
    docker login <registry_login_server> -u <registry_username> -p <registry_password>
    ```
    *Explanation:* Authenticates Docker with your newly created Azure registry using the credentials outputted by Terraform. Replace the bracketed placeholders with your actual values.

* **Tag the Local Docker Image:**
    ```bash
    docker tag celestial-bodies-classifier:latest <registry_login_server>/celestial-bodies-classifier:latest
    ```
    *Explanation:* Creates an alias for your local BentoML image (`celestial-bodies-classifier:latest`). The new tag prefixes the image name with your ACR login server address, which tells Docker exactly where to upload it.

* **Push the Image to Azure:**
    ```bash
    docker push <registry_login_server>/celestial-bodies-classifier:latest
    ```
    *Explanation:* Uploads the tagged image from your local machine to your Azure Container Registry.
