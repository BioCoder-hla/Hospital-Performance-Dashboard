# Hospital Performance Intelligence Platform

An interactive web dashboard for visualizing and analyzing U.S. hospital performance data. Built with Python (Flask), R (for ETL), JavaScript (Chart.js, Plotly), and MySQL.

![Dashboard Screenshot](https://github.com/BioCoder-hla/Hospital-Performance-Dashboard/blob/main/Dashboard%20Screenshot)

## Table of Contents
- [Overview](#-overview)
- [Key Features](#-key-features)
- [Project Architecture](#-project-architecture)
- [Tech Stack](#-tech-stack)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Dataset](#-dataset)
- [Contact](#-contact)
- [License](#-license)

## 🔭 Overview

The Hospital Performance Intelligence Platform is a full-stack web application designed to provide a clear, interactive, and insightful view of hospital performance data across the United States. Leveraging a powerful backend built with Flask and a dynamic frontend powered by Chart.js and Plotly, this dashboard allows users to analyze key performance indicators, compare states, and identify trends in healthcare quality.

This project demonstrates a complete data pipeline, from raw data ingestion and cleaning with R, to storage in a relational database, to exposure via a RESTful API, and finally to visualization in a user-friendly web interface.

## ✨ Key Features

- **Interactive U.S. Map:** Visualize average performance scores by state with a color-coded choropleth map. Click on a state to filter the entire dashboard.
- **Dynamic KPIs:** Key Performance Indicators (Total Hospitals, Average Readmission Score) update instantly based on the selected state or national view.
- **Detailed Charts & Tables:**
    - **Performance by Volume:** A bar chart comparing scores for hospitals of different sizes.
    - **National Performance Rating:** A donut chart showing the distribution of measures that are better, average, or worse than the national average.
    - Data tables for Top 5 Worst Hospitals (Heart Failure), Top 5 Worst Measures, and State-by-State performance.
- **Responsive UI:** The layout adapts seamlessly to different screen sizes.
- **Light & Dark Mode:** A sleek, user-toggleable theme for optimal viewing comfort.
- **Data Export:** Easily export charts as PNGs and tables as CSVs with a single click.

## 🏗️ Project Architecture

The application follows a multi-tiered architecture, separating the data processing, storage, and presentation layers.

```
1. Data Pipeline (R)      2. Database (MySQL)         3. Backend API (Flask)     4. Frontend (JS)
┌───────────────────────┐   ┌───────────────────────┐   ┌────────────────────────┐   ┌───────────────────┐
│ Ingest Raw CMS Data   │   │                       │   │                        │   │                   │
│ Clean & Transform     ├─► │  Star Schema Database ├─► │   Flask RESTful API    ├─► │  Interactive UI   │
│ (tidyverse, janitor)  │   │   (hospitals, etc.)   │   │   (e.g., /api/kpis)    │   │ (Plotly, Chart.js)│
└───────────────────────┘   └───────────────────────┘   └────────────────────────┘   └───────────────────┘
```

## 🛠️ Tech Stack

| Layer           | Technologies Used                               |
|-----------------|-------------------------------------------------|
| **Data Pipeline** | R, tidyverse, janitor, DBI, RMySQL              |
| **Database**      | MySQL (Designed with a Star Schema)             |
| **Backend**       | Python, Flask                                   |
| **Frontend**      | HTML5, CSS3, JavaScript                         |
| **Visualization** | Chart.js, Plotly.js                             |
| **Environment**   | XAMPP / LAMP Stack, Visual Studio Code          |

## 🚀 Getting Started

To run this project locally, follow these steps.

### Prerequisites

- Python 3.x
- R and RStudio
- XAMPP or another LAMP/WAMP stack with an active MySQL server.

### Installation

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/BioCoder-hla/Hospital-Performance-Dashboard.git
    cd Hospital-Performance-Dashboard
    ```

2.  **Set up the Database:**
    - Ensure your MySQL server is running.
    - Create a database named `hospital_performance`.
    - Run the provided R script (`your_script_name.R`) to download the raw data, clean it, and populate the MySQL database tables.

3.  **Configure the Python Backend:**
    - Open `app.py` and update the `DB_CONFIG` dictionary with your MySQL credentials.
      ```python
      DB_CONFIG = {
          'user': 'root',
          'password': '',  # Your password
          'host': '127.0.0.1',
          'database': 'hospital_performance',
          'unix_socket': '/opt/lampp/var/mysql/mysql.sock' # Update this path for your system
      }
      ```
    - Install Python dependencies:
      ```bash
      pip install Flask mysql-connector-python
      ```

4.  **Run the Application:**
    ```bash
    python app.py
    ```
    - The application will start on a local port (e.g., `http://127.0.0.1:5000`). Open this URL in your web browser.

## 📊 Dataset

The data for this project was sourced from the Centers for Medicare & Medicaid Services (CMS).

- **Source:** [CMS.gov Provider Data](https://data.cms.gov/provider-data/dataset/632h-zaca)
- **Dataset Name:** Unplanned Hospital Visits – Hospital
- **Key Fields Used:** `Facility.ID`, `Facility.Name`, `Measure.ID`, `Measure.Name`, `Score`, `Denominator`.

## 📬 Contact

Tinotenda Wayne Hlatywayo  
📧 Email: hlatwayne@gmail.com  
💼 GitHub: [@BioCoder-hla](https://github.com/BioCoder-hla)

## 📄 License

This project is licensed under the MIT License. See the `LICENSE` file for details.
