# app.py - FINAL, SIMPLIFIED, AND CORRECTED

from flask import Flask, jsonify, render_template, request
import mysql.connector
import os
import socket

app = Flask(__name__)

# --- Database Configuration ---
DB_CONFIG = {
    'user': 'root', 'password': '', 'host': '127.0.0.1',
    'database': 'hospital_performance',
    'unix_socket': '/opt/lampp/var/mysql/mysql.sock'
}

def get_db_connection():
    return mysql.connector.connect(**DB_CONFIG)

def execute_query(query, params=None):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(query, params or ())
        results = cursor.fetchall()
        return results
    except mysql.connector.Error as err:
        print(f"Database error: {err}")
        return []
    finally:
        cursor.close()
        conn.close()

# --- API Endpoints ---

@app.route('/api/kpis')
def get_kpis():
    state = request.args.get('state')
    params = [state] if state else []
    
    hospitals_query = "SELECT COUNT(DISTINCT facility_id) AS total_hospitals FROM hospitals" + (" WHERE state = %s" if state else "")
    hospitals_result = execute_query(hospitals_query, params)
    
    avg_score_query = "SELECT ROUND(AVG(p.score), 2) as average_readmission_score FROM performance_data p JOIN hospitals h ON p.facility_id = h.facility_id WHERE p.score IS NOT NULL AND (p.measure_id LIKE 'READM%%' OR p.measure_id LIKE 'EDAC%%')" + (" AND h.state = %s" if state else "")
    avg_score_result = execute_query(avg_score_query, params)

    return jsonify({
        'total_hospitals': hospitals_result[0]['total_hospitals'] if hospitals_result else 0,
        'average_readmission_score': avg_score_result[0]['average_readmission_score'] if avg_score_result else 'N/A'
    })

@app.route('/api/worst-measures')
def get_worst_measures():
    state = request.args.get('state')
    params = [state] if state else []
    
    query = """
        SELECT 
            m.measure_name, 
            COUNT(p.performance_id) AS number_of_hospitals_reporting,
            ROUND(AVG(p.score), 2) AS average_score
        FROM 
            performance_data p
        JOIN 
            hospitals h ON p.facility_id = h.facility_id
        JOIN
            measures m ON p.measure_id = m.measure_id
        WHERE 
            p.score IS NOT NULL 
            AND (p.measure_id LIKE 'READM%%' OR p.measure_id LIKE 'EDAC%%')
    """
    if state:
        query += " AND h.state = %s"
    query += """
        GROUP BY 
            m.measure_name
        ORDER BY 
            average_score DESC
        LIMIT 5;
    """
    
    results = execute_query(query, params)
    if not results:
        print("No data returned for worst measures. Check database content.")
    return jsonify(results)

@app.route('/api/national-performance')
def get_national_performance():
    state = request.args.get('state')
    params = [state] if state else []
    
    query = """
        SELECT 
            performance_category, 
            COUNT(*) AS number_of_measures,
            ROUND((COUNT(*) / (SELECT COUNT(*) FROM performance_data WHERE performance_category IS NOT NULL)) * 100, 1) AS percentage
        FROM 
            performance_data p
    """
    if state:
        query += " JOIN hospitals h ON p.facility_id = h.facility_id WHERE h.state = %s AND performance_category IS NOT NULL AND performance_category != '' "
    else:
        query += " WHERE performance_category IS NOT NULL AND performance_category != '' "
    query += """
        GROUP BY 
            performance_category
        ORDER BY 
            performance_category;
    """
    
    results = execute_query(query, params)
    if not results:
        print("No data returned for national performance. Check performance_category column or data.")
    return jsonify(results)

@app.route('/api/performance-by-volume')
def get_performance_by_volume():
    state = request.args.get('state')
    params = [state] if state else []
    
    query = "SELECT CASE WHEN p.denominator <= 100 THEN 'Small' WHEN p.denominator > 100 AND p.denominator <= 500 THEN 'Medium' WHEN p.denominator > 500 AND p.denominator <= 1000 THEN 'Large' ELSE 'Very Large' END AS tier, ROUND(AVG(p.score), 2) AS average_score FROM performance_data p JOIN hospitals h ON p.facility_id = h.facility_id WHERE p.denominator IS NOT NULL AND p.score IS NOT NULL AND (p.measure_id LIKE 'READM%%' OR p.measure_id LIKE 'EDAC%%')"
    if state:
        query += " AND h.state = %s"
    query += " GROUP BY tier ORDER BY tier;"
    
    return jsonify(execute_query(query, params))

@app.route('/api/top-hospitals')
def get_top_hospitals():
    state = request.args.get('state')
    params = [state] if state else []

    query = """
        SELECT DISTINCT h.facility_name, h.city_town, h.state, p.score
        FROM performance_data p JOIN hospitals h ON p.facility_id = h.facility_id
        WHERE p.measure_id = 'READM_30_HF' AND p.score IS NOT NULL
    """
    if state:
        query += " AND h.state = %s"
    query += " ORDER BY p.score DESC LIMIT 5;"
    
    return jsonify(execute_query(query, params))
    
@app.route('/api/state-details')
def get_state_details():
    query = """
        SELECT
            h.state,
            COUNT(DISTINCT h.facility_id) AS number_of_hospitals,
            SUM(p.denominator) AS total_patient_volume,
            MIN(p.score) AS min_score,
            MAX(p.score) AS max_score,
            ROUND(AVG(p.score), 2) as average_score
        FROM 
            performance_data p 
        JOIN 
            hospitals h ON p.facility_id = h.facility_id
        WHERE 
            p.score IS NOT NULL 
            AND (p.measure_id LIKE 'READM%%' OR p.measure_id LIKE 'EDAC%%')
        GROUP BY 
            h.state
        HAVING 
            number_of_hospitals > 20
        ORDER BY
            average_score DESC;
    """
    return jsonify(execute_query(query))

@app.route('/api/performance-by-state')
def get_performance_by_state():
    query = "SELECT h.state, ROUND(AVG(p.score), 2) as average_state_score FROM performance_data p JOIN hospitals h ON p.facility_id = h.facility_id WHERE p.score IS NOT NULL AND (p.measure_id LIKE 'READM%%' OR p.measure_id LIKE 'EDAC%%') GROUP BY h.state HAVING COUNT(DISTINCT h.facility_id) > 20;"
    return jsonify(execute_query(query))

@app.route('/')
def index():
    return render_template('index.html')

if __name__ == '__main__':
    port = 5000
    while True:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            if s.connect_ex(('localhost', port)) != 0:
                break
            port += 1
    app.run(host='127.0.0.1', port=port, debug=True)
