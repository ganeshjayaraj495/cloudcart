import os
import boto3
import psycopg2
import subprocess
import json
import pandas as pd
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
    cmd = "aws secretsmanager get-secret-value --secret-id 'arn:aws:secretsmanager:eu-north-1:078038151681:secret:rds!cluster-3927afa8-a49b-492e-958d-26c25d81c59c-hTFErK' --query SecretString --output text"
    res = subprocess.check_output(cmd, shell=True).decode('utf-8')
    return json.loads(res)['password']

s3_client = boto3.client('s3')

@app.route('/')
def index():
    products = []
    try:
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
        cur.execute("SELECT id, name, image_url, created_at FROM products ORDER BY created_at DESC;")
        products = cur.fetchall()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error fetching products: {e}")
        
    return render_template('index.html', products=products)

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        flash('No file part')
        return redirect(url_for('index'))
    file = request.files['file']
    if file.filename == '':
        flash('No selected file')
        return redirect(url_for('index'))
    if file:
        filename = secure_filename(file.filename)
        s3_client.upload_fileobj(file, S3_BUCKET, f"products/{filename}")
        image_url = f"https://{S3_BUCKET}.s3.eu-north-1.amazonaws.com/products/{filename}"
        
        try:
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
            cur.execute("INSERT INTO products (name, image_url) VALUES (%s, %s)", (filename, image_url))
            conn.commit()
            cur.close()
            conn.close()
            flash('Successfully uploaded image and saved product to database!')
        except Exception as e:
            flash(f'Database error: {str(e)}')
            
    return redirect(url_for('index'))

@app.route('/upload_excel', methods=['POST'])
def upload_excel():
    if 'excel_file' not in request.files:
        flash('No file part selected')
        return redirect(url_for('index'))
    
    file = request.files['excel_file']
    if file.filename == '':
        flash('No file selected')
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
                
            conn.commit()
            cur.close()
            conn.close()
            
            flash(f'Successfully imported {count} products from Excel catalog!')
        except Exception as e:
            flash(f'Excel import failed: {str(e)}')
    else:
        flash('Invalid file format. Please upload an Excel (.xlsx or .xls) file.')
        
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
