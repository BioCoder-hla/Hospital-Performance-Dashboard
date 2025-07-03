document.addEventListener('DOMContentLoaded', () => {
    let activeState = null;
    const charts = {};
    let nationalAvg = null;

    // --- HELPER FUNCTIONS FOR THEMEING ---
    const getThemeColors = () => {
        const isDarkMode = document.body.getAttribute('data-theme') === 'dark';
        return {
            textColor: getComputedStyle(document.body).getPropertyValue('--text-color').trim(),
            mapText: isDarkMode ? 'rgba(255,255,255,0.7)' : 'rgba(0,0,0,0.7)'
        };
    };

    const updateVisualsForTheme = () => {
        const { textColor, mapText } = getThemeColors();
        if (charts.volume) {
            charts.volume.options.scales.x.ticks.color = textColor;
            charts.volume.options.scales.y.ticks.color = textColor;
            charts.volume.update();
        }
        if (charts.donut) {
            charts.donut.options.plugins.legend.labels.color = textColor;
            charts.donut.update();
        }
        const mapElement = document.getElementById('us-map');
        if (mapElement.data) {
            Plotly.restyle(mapElement, { 'textfont.color': [mapText] }, [1]);
            Plotly.restyle(mapElement, { 'colorbar.title.font.color': textColor, 'colorbar.tickfont.color': textColor }, [0]);
        }
    };

    // NEW: Function to update the theme toggle button's text and icon
    const updateThemeButton = (theme) => {
        const themeIcon = document.getElementById('theme-icon');
        const themeText = document.getElementById('theme-text');
        const toggleButton = document.getElementById('dark-mode-toggle');

        if (theme === 'dark') {
            themeIcon.className = 'fas fa-sun';
            themeText.textContent = 'Light Mode';
            toggleButton.title = 'Switch to Light Mode';
        } else {
            themeIcon.className = 'fas fa-moon';
            themeText.textContent = 'Dark Mode';
            toggleButton.title = 'Switch to Dark Mode';
        }
    };

    // --- INITIALIZATION AND EVENT LISTENERS ---
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)');
    const savedTheme = localStorage.getItem('theme') || (prefersDark.matches ? 'dark' : 'light');
    document.body.setAttribute('data-theme', savedTheme);
    updateThemeButton(savedTheme); // Set initial button state

    document.getElementById('dark-mode-toggle').addEventListener('click', () => {
        const currentTheme = document.body.getAttribute('data-theme');
        const newTheme = currentTheme === 'light' ? 'dark' : 'light';
        document.body.setAttribute('data-theme', newTheme);
        localStorage.setItem('theme', newTheme);
        updateThemeButton(newTheme); // Update button on toggle
        updateVisualsForTheme();
    });

    const updateDashboard = (state = null) => {
        activeState = state;
        const stateParam = state ? `?state=${state}` : '';
        const filterStatus = document.getElementById('filter-status');
        if (state) {
            document.getElementById('filter-text').textContent = `Showing data for: ${state}`;
            filterStatus.style.display = 'flex';
        } else {
            filterStatus.style.display = 'none';
        }
        fetch(`/api/kpis${stateParam}`).then(res => res.json()).then(data => {
            document.getElementById('kpi-total-hospitals').textContent = data?.total_hospitals ? data.total_hospitals.toLocaleString() : 'N/A';
            nationalAvg = parseFloat(data?.average_readmission_score) || null;
            document.getElementById('kpi-avg-score').textContent = nationalAvg !== null ? nationalAvg : 'N/A';
            fetchPerformanceData(stateParam);
            fetchVolumeData(stateParam);
            fetchTopHospitals(stateParam);
            fetchWorstMeasures(stateParam);
        }).catch(error => console.error('Error fetching KPIs:', error));
    };

    const fetchPerformanceData = (stateParam) => {
        fetch(`/api/national-performance${stateParam}`).then(res => res.json()).then(data => {
            if (charts.donut) charts.donut.destroy();
            const ctx = document.getElementById('performance-donut-chart').getContext('2d');
            if (data.length === 0) {
                ctx.canvas.parentElement.innerHTML = '<p>No performance data available</p>';
                return;
            }
            const { textColor } = getThemeColors();
            const backgroundColors = data.map(d => {
                switch(d.performance_category) {
                    case 'Better than National Average': return '#22c55e';
                    case 'Average': return '#f97316';
                    case 'Worse than National Average': return '#ef4444';
                    default: return '#6b7280';
                }
            });
            charts.donut = new Chart(ctx, {
                type: 'doughnut',
                data: {
                    labels: data.map(d => d.performance_category),
                    datasets: [{ data: data.map(d => d.number_of_measures), backgroundColor: backgroundColors }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { position: 'bottom', labels: { color: textColor } },
                        tooltip: {
                            callbacks: {
                                label: (context) => `${context.label}: ${context.raw.toLocaleString()} measures (${(data[context.dataIndex].percentage || 0)}%)`
                            }
                        }
                    }
                }
            });
        }).catch(error => console.error('Error fetching performance data:', error));
    };

    const fetchVolumeData = (stateParam) => {
        fetch(`/api/performance-by-volume${stateParam}`).then(res => res.json()).then(data => {
            if (charts.volume) charts.volume.destroy();
            const ctx = document.getElementById('volume-bar-chart').getContext('2d');
            const { textColor } = getThemeColors();
            charts.volume = new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: data.map(d => d.tier),
                    datasets: [{ label: 'Average Score', data: data.map(d => d.average_score), backgroundColor: '#3b82f6' }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { display: false } },
                    scales: {
                        y: { beginAtZero: true, grid: { display: false }, ticks: { color: textColor } },
                        x: { grid: { display: false }, ticks: { color: textColor } }
                    }
                }
            });
        }).catch(error => console.error('Error fetching volume data:', error));
    };

    const fetchTopHospitals = (stateParam) => {
        fetch(`/api/top-hospitals${stateParam}`).then(res => res.json()).then(data => {
            const tableBody = document.querySelector('#top-hospitals-table tbody');
            tableBody.innerHTML = '';
            data.forEach(h => {
                const row = tableBody.insertRow();
                row.insertCell(0).textContent = h.facility_name;
                row.insertCell(1).textContent = h.city_town;
                row.insertCell(2).textContent = h.state;
                row.insertCell(3).textContent = parseFloat(h.score).toFixed(2);
            });
        }).catch(error => console.error('Error fetching top hospitals:', error));
    };

    const fetchWorstMeasures = (stateParam) => {
        fetch(`/api/worst-measures${stateParam}`).then(res => res.json()).then(data => {
            const tableBody = document.querySelector('#worst-measures-table tbody');
            tableBody.innerHTML = '';
            data.forEach(m => {
                const row = tableBody.insertRow();
                row.insertCell(0).textContent = m.measure_name;
                row.insertCell(1).textContent = m.number_of_hospitals_reporting.toLocaleString();
                row.insertCell(2).textContent = parseFloat(m.average_score).toFixed(2);
            });
        }).catch(error => console.error('Error fetching worst measures:', error));
    };

    const fetchInitialPageData = () => {
        fetch('/api/performance-by-state').then(res => res.json()).then(data => {
            const mapElement = document.getElementById('us-map');
            const { textColor, mapText } = getThemeColors();
            const choroplethTrace = {
                type: 'choropleth', locationmode: 'USA-states', locations: data.map(d => d.state),
                z: data.map(d => d.average_state_score), hovertemplate: '<b>%{z:.2f}</b><extra></extra>',
                colorscale: 'Reds',
                colorbar: { title: 'Avg Score', titlefont: { color: textColor }, tickfont: { color: textColor } }
            };
            const textTrace = {
                type: 'scattergeo', locationmode: 'USA-states', locations: data.map(d => d.state),
                text: data.map(d => d.state), mode: 'text',
                textfont: { family: 'Arial', size: 10, color: mapText },
                hoverinfo: 'none'
            };
            const mapData = [choroplethTrace, textTrace];
            const layout = {
                geo: { scope: 'usa', projection: { type: 'albers usa' }, showlakes: false, bgcolor: 'rgba(0,0,0,0)' },
                margin: { t: 0, b: 0, l: 0, r: 0 }, paper_bgcolor: 'rgba(0,0,0,0)', showlegend: false
            };
            const config = { responsive: true, displayModeBar: false };
            Plotly.newPlot(mapElement, mapData, layout, config);
            mapElement.on('plotly_click', (data) => updateDashboard(data.points[0].location));
        }).catch(error => console.error('Error fetching map data:', error));

        fetch('/api/state-details').then(res => res.json()).then(data => {
            const tableBody = document.querySelector('#state-performance-table tbody');
            tableBody.innerHTML = '';
            data.forEach(s => {
                const row = tableBody.insertRow();
                row.insertCell(0).textContent = s.state;
                row.insertCell(1).textContent = s.number_of_hospitals.toLocaleString();
                row.insertCell(2).textContent = s.total_patient_volume.toLocaleString();
                row.insertCell(3).textContent = parseFloat(s.min_score).toFixed(2);
                row.insertCell(4).textContent = parseFloat(s.max_score).toFixed(2);
                row.insertCell(5).textContent = parseFloat(s.average_score).toFixed(2);
            });
        }).catch(error => console.error('Error fetching state details data:', error));
    };

    document.getElementById('reset-filter-btn').addEventListener('click', () => updateDashboard());
    document.querySelectorAll('.export-btn').forEach(button => {
        button.addEventListener('click', (e) => {
            const targetId = e.currentTarget.dataset.target;
            const stateName = activeState || 'national';
            const filename = `${targetId}_${stateName}`;
            if (targetId.includes('table')) {
                const table = document.getElementById(targetId);
                let csvContent = "data:text/csv;charset=utf-8,";
                table.querySelectorAll("tr").forEach(row => {
                    let rowData = [];
                    row.querySelectorAll("th, td").forEach(cell => rowData.push(`"${cell.textContent}"`));
                    csvContent += rowData.join(",") + "\r\n";
                });
                const link = document.createElement("a");
                link.setAttribute("href", encodeURI(csvContent));
                link.setAttribute("download", `${filename}.csv`);
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
            } else if (targetId.includes('chart')) {
                const canvas = document.getElementById(targetId);
                const link = document.createElement('a');
                link.href = canvas.toDataURL('image/png', 1.0);
                link.download = `${filename}.png`;
                link.click();
            } else if (targetId.includes('map')) {
                const mapDiv = document.getElementById(targetId);
                Plotly.toImage(mapDiv, { format: 'png', width: 1200, height: 800 }).then(dataUrl => {
                    const link = document.createElement('a');
                    link.href = dataUrl;
                    link.download = `${filename}.png`;
                    link.click();
                });
            }
        });
    });

    fetchInitialPageData();
    updateDashboard();
});
