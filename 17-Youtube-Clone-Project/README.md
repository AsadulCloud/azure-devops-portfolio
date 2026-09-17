# 🎬 YouTube Clone — End-to-End CI/CD with Azure DevOps

[![Azure Pipelines](https://img.shields.io/badge/Azure%20Pipelines-CI%2FCD-0078D4?logo=azurepipelines&logoColor=white)](https://azure.microsoft.com/en-us/products/devops/pipelines)
[![React](https://img.shields.io/badge/React-18-61DAFB?logo=react&logoColor=black)](https://reactjs.org/)
[![Material UI](https://img.shields.io/badge/Material%20UI-5-0081CB?logo=mui&logoColor=white)](https://mui.com/)
[![Azure App Service](https://img.shields.io/badge/Azure%20App%20Service-Deployed-0078D4?logo=microsoftazure&logoColor=white)](https://azure.microsoft.com/en-us/products/app-service)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> A production-ready **React + Material UI** YouTube Clone fully automated with a multi-stage **Azure DevOps YAML pipeline** and deployed to **Azure App Service**.

**🔗 Live Demo:** [techtutorialwithasad-gyhqeneffqhqd8bn.polandcentral-01.azurewebsites.net](https://techtutorialwithasad-gyhqeneffqhqd8bn.polandcentral-01.azurewebsites.net)

**🔗 Live Demo:** *Not currently live*

> ℹ️ **Note:** After completing and testing this project, the Azure resources were intentionally decommissioned to avoid ongoing costs on a free-tier subscription. The full CI/CD pipeline, code, and screenshots below demonstrate the working, successfully deployed application. The project can be redeployed on request — see [Getting Started](#-getting-started-locally) or reach out directly.

---

## 🎯 Project Goal

This is not just another frontend project.  
It is a **practical DevOps case study** designed to demonstrate real-world CI/CD skills that recruiters and hiring managers look for in Junior Azure DevOps / Cloud Engineers:

- Multi-stage YAML pipelines
- Secure secret management
- Artifact handling between stages
- Static site deployment to Azure App Service
- Debugging production issues (API keys, runtime stack, rate limits)
- Build-time environment variable injection in React

---

## 🏗️ Architecture Overview

```
┌─────────────────┐     push to main      ┌──────────────────────┐
│  Azure Repos /  │ ────────────────────► │   Azure Pipelines    │
│     GitHub      │                       │   (YAML Trigger)     │
└─────────────────┘                       └──────────┬───────────┘
                                                     │
                       ┌─────────────────────────────┴─────────────────────────────┐
                       │                      BUILD STAGE                           │
                       │  • npm ci                                                 │
                       │  • Inject REACT_APP_RAPID_API_KEY (secret variable)       │
                       │  • npm run build                                          │
                       │  • PublishBuildArtifacts → "drop"                         │
                       └─────────────────────────────┬─────────────────────────────┘
                                                     │
                       ┌─────────────────────────────┴─────────────────────────────┐
                       │                     DEPLOY STAGE                           │
                       │  • DownloadBuildArtifacts                                 │
                       │  • Deploy to Azure App Service (STATICSITE|1.0)            │
                       └─────────────────────────────┬─────────────────────────────┘
                                                     │
                                                     ▼
                                       🌐 Live App on Azure App Service
```

---

## 🛠️ Tech Stack

| Category              | Technology                                      | Purpose                              |
|-----------------------|-------------------------------------------------|--------------------------------------|
| Frontend              | React 18 + Material UI 5                        | Modern, responsive UI                |
| API                   | RapidAPI – YouTube v31 (`ytdlfree`)             | Video data & search                  |
| CI/CD                 | Azure DevOps Pipelines (YAML)                   | Fully automated Build + Deploy       |
| Hosting               | Azure App Service (Linux – Static Site)         | Production hosting                   |
| Secrets Management    | Azure Pipeline Secret Variables                 | Secure API key injection             |
| Version Control       | Azure Repos / Git                               | Source of truth                      |

---

## 📂 Project Structure

```
Youtube_Clone/
├── public/                     # Static assets
├── src/
│   ├── components/             # Navbar, VideoCard, ChannelCard, etc.
│   ├── utils/
│   │   ├── fetchFromAPI.js     # Centralized RapidAPI client
│   │   └── constants.js
│   ├── App.js
│   └── index.js
├── azure-pipelines.yml         # Multi-stage CI/CD pipeline
├── package.json
└── README.md
```

---

## ⚙️ Azure DevOps Pipeline Highlights

The pipeline is defined in a single `azure-pipelines.yml` file and triggers on every push to `main`.

### Build Stage
- Installs dependencies
- Securely creates `.env` file with `REACT_APP_RAPID_API_KEY` from a **pipeline secret variable**
- Runs production build (`npm run build`)
- Publishes the `build/` folder as a pipeline artifact named `drop`

### Deploy Stage
- Downloads the artifact
- Deploys to Azure App Service using the correct **STATICSITE|1.0** runtime stack

> **Security Best Practice:** The RapidAPI key is **never** stored in the repository. It is injected only at build time.

---

## 🐛 Real Challenges Solved (and Why They Matter)

| Challenge | Solution | Skill Demonstrated |
|-----------|----------|--------------------|
| Classic Release Pipelines not available | Designed a clean multi-stage YAML pipeline | Modern Azure DevOps practices |
| Wrong runtime stack (`NODE` instead of static) | Corrected to `STATICSITE\|1.0` | Azure App Service configuration |
| Build artifacts not available in Deploy stage | Used `PublishBuildArtifacts` + `DownloadBuildArtifacts` | Understanding agent isolation |
| React environment variables not available at runtime | Injected `REACT_APP_*` variables during the Build stage | Build-time vs Runtime knowledge |
| 401 / 429 API errors after deployment | Diagnosed via browser DevTools + corrected RapidAPI subscription | Production debugging |
| Slow pipeline (17–25 min) | Identified lack of dependency caching as the bottleneck | Performance optimization mindset |

These are the exact types of issues junior engineers face in real jobs — and solving them shows practical experience.

---

## 🚀 Run Locally

```bash
git clone https://github.com/<your-username>/Youtube_Clone.git
cd Youtube_Clone
npm install
```

Create a `.env` file in the root:

```env
REACT_APP_RAPID_API_KEY=your_rapidapi_key_here
```

Start the development server:

```bash
npm start
```

> Get a free API key here: [RapidAPI – YouTube v31](https://rapidapi.com/ytdlfree/api/youtube-v31)

---

## 📸 Screenshots

| Home Page | Search Results | Pipeline Success |
|-----------|----------------|------------------|
| ![Home](./screenshots/Home_Page.png) | ![Search](./screenshots/Search.png) | ![Pipeline](./screenshots/Pipeline_Success.png) |



---

## 📚 Key Skills Demonstrated

- Designing and maintaining multi-stage YAML pipelines in Azure DevOps
- Secure secret management with pipeline variables
- Artifact management across pipeline stages
- Deploying static React applications to Azure App Service
- Understanding React environment variable behavior (build-time injection)
- Debugging real production issues using logs + browser DevTools
- Working with third-party APIs, rate limits, and subscriptions

---

## 🙋 About Me

**Md Asadul Howlader**  
Junior Azure DevOps / Cloud Engineer  
📍 Lisbon, Portugal  

I’m passionate about building reliable CI/CD pipelines and deploying applications to the cloud. This project is one of the practical ways I continuously improve my Azure DevOps and cloud engineering skills.

**Let’s connect!**  
- LinkedIn: [Your LinkedIn Profile]  
- GitHub: [Your GitHub Profile]  
- Email: [your.email@example.com]

---

⭐ If you found this project useful or interesting, feel free to star the repository!  
I’m always open to feedback, collaboration, or job opportunities in Azure DevOps / Cloud Engineering.
