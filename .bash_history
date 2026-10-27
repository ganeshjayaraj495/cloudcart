sudo su
psql "host=$RDSHOST port=5432 dbname=postgres user=postgres sslmode=verify-full sslrootcert=./global-bundle.pem password=$(aws secretsmanager get-secret-value --secret-id 'arn:aws:secretsmanager:eu-north-1:078038151681:secret:rds!cluster-3927afa8-a49b-492e-958d-26c25d81c59c-hTFErK' --query SecretString --output text | jq -r '.password')"
psql "host=cloudcart-rds-sg.cluster-czmm80mgq3pb.eu-north-1.rds.amazonaws.com port=5432 dbname=postgres user=postgres sslmode=verify-full sslrootcert=./global-bundle.pem password=$(aws secretsmanager get-secret-value --secret-id 'arn:aws:secretsmanager:eu-north-1:078038151681:secret:rds!cluster-3927afa8-a49b-492e-958d-26c25d81c59c-hTFErK' --query SecretString --output text | jq -r '.password')"
CREATE DATABASE cloudcart;
\c cloudcart;
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    price DECIMAL(10,2) NOT NULL,
    image_key VARCHAR(255) NOT NULL
);
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    customer_email VARCHAR(100) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO products (name, description, price, image_key) VALUES
('Laptop', 'High-performance student laptop', 45000.00, 'products/laptop.jpg'),
('Headphones', 'Noise-canceling wireless headphones', 2500.00, 'products/headphones.jpg'),
('Keyboard', 'Custom mechanical keyboard', 1500.00, 'products/keyboard.jpg');
nc -zv cloudcart-rds-sg.cluster-czmm80mgq3pb.eu-north-1.rds.amazonaws.com 5432
nano app.py
mkdir templates
nano templates/index.html
ls -R
sudo yum update -y
sudo yum install python3-pip -y
pip3 install flask boto3 werkzeug
python3 app.py
nohup python3 app.py > app.log 2>&1 &
nano app.py
cat /dev/null > app.py
nano app.py
pkill -f app.py
nohup python3 app.py > app.log 2>&1 &
nano templates/index.html
pkill -f app.py
nohup python3 app.py > app.log 2>&1 &
export RDSHOST="cloudcart-rds-sg.cluster-czmm80mgq3pb.eu-north-1.rds.amazonaws.com" 
psql "host=$RDSHOST port=5432 dbname=postgres user=postgres sslmode=verify-full sslrootcert=./global-bundle.pem password=$(aws secretsmanager get-secret-value --secret-id 'arn:aws:secretsmanager:eu-north-1:078038151681:secret:rds!cluster-3927afa8-a49b-492e-958d-26c25d81c59c-hTFErK' --query SecretString --output text | jq -r '.password')"
nano app.py
cat /dev/null > app.py
nano app.py
nano templates/index.html
pkill -f app.py
nohup python3 app.py > app.log 2>&1 &
pip3 install psycopg2-binary
nano test_db.py
export RDSHOST="cloudcart-rds-sg.cluster-czmm80mgq3pb.eu-north-1.rds.amazonaws.com" 
psql "host=$RDSHOST port=5432 dbname=postgres user=postgres sslmode=verify-full sslrootcert=./global-bundle.pem password=$(aws secretsmanager get-secret-value --secret-id 'arn:aws:secretsmanager:eu-north-1:078038151681:secret:rds!cluster-3927afa8-a49b-492e-958d-26c25d81c59c-hTFErK' --query SecretString --output text | jq -r '.password')"
nano app.py
pkill -f app.py
nohup python3 app.py > app.log 2>&1 &
pkill -f app.py
nohup python3 app.py > app.log 2>&1 &
nano templates/index.html
pip3 install pandas openpyxl
import os
import boto3
import psycopg2
import subprocess
import json
import pandas as pd  # <--- 1. ADD THIS AT THE TOP WITH YOUR OTHER IMPORTS
from flask import Flask, render_template, request, redirect, url_for, flash
from werkzeug.utils import secure_filename
app = Flask(__name__)
app.secret_key = 'cloudcart_secret_key'
# Configuration
S3_BUCKET = 'cloudcart-product-images-1'
RDS_HOST = 'cloudcart-rds-sg.cluster-czmm80mgq3pb.eu-north-1.rds.amazonaws.com'
DB_NAME = 'postgres'
DB_USER = 'postgres'
def get_db_password():
    res = subprocess.check_output(cmd, shell=True).decode('utf-8')
    return json.loads(res)['password']
s3_client = boto3.client('s3')
@app.route('/')
def index():
    # (Your catalog fetching code here)
    return render_template('index.html')
@app.route('/upload', methods=['POST'])
def upload_file():
    # (Your existing single-file upload code here)
    return redirect(url_for('index'))
# ==========================================
# 2. PASTE THE NEW EXCEL ROUTE RIGHT HERE:
# ==========================================
@app.route('/upload_excel', methods=['POST'])
def upload_excel():
    if 'excel_file' not in request.files:;         flash('No file part selected')
        return redirect(url_for('index'))
    
    file = request.files['excel_file']
    if file.filename == '':;         flash('No file selected')
        return redirect(url_for('index'))
    
    if file and (file.filename.endswith('.xlsx') or file.filename.endswith('.xls')):
        try:
            df = pd.read_excel(file)
            
            conn = psycopg2.connect(
                host=RDS_HOST,
                database=DB_NAME,
                user=DB_USER,
                password=get_db_password(),
                port=5432,
                sslmode="verify-full",
                sslrootcert="global-bundle.pem"
            )
            cur = conn.cursor()
            
            count = 0
            for _, row in df.iterrows():
                name = row.get('Product Name', 'Unnamed Product')
                image_url = row.get('S3 Image URL', '')
                
                cur.execute("INSERT INTO products (name, image_url) VALUES (%s, %s)", (name, image_url))
                count += 1
                
            conn.commit()             cur.close()
            conn.close()                          flash(f'Successfully imported {count} products from Excel catalog!')
        except Exception as e:
            flash(f'Excel import failed: {str(e)}')
    else:
        flash('Invalid file format. Please upload an Excel (.xlsx or .xls) file.')
        
    return redirect(url_for('index'))
if __name__ == '__main__':;     app.run(host='0.0.0.0', port=5000)
