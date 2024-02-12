import subprocess
import _scorecard_utils
import os
from weasyprint import HTML
import shutil
from google.cloud import storage
from calitp_data_analysis.sql import to_snakecase
import pandas as pd
def load_file_project_names()-> list:
    """
    Load all the unique projects to run in a loop
    """
    df = to_snakecase(pd.read_excel(f"{_scorecard_utils.GCS_FILE_PATH}{_scorecard_utils.canonical_file}", sheet_name = "Project Intake Info"))
    df = df.loc[~df.project_name.isin(_scorecard_utils.not_moving_forward)]
    
    df = df[['district','project_name']].drop_duplicates().dropna()
    df = df.sort_values(by = ['project_name'])
    
    # Clean up project names as the file names
    df['file_names'] = df.project_name
    df.file_names = df.file_names.str.replace(' ','_').str.lower()
    df.district = df.district.str.replace(r'\n', '_')
    df['file_names'] = "d" + df.district + "_" + df.file_names + '.ipynb'
    
    # List out unique values to produce pdfs in a loop
    file_names = list(df.file_names.unique())
    project_names = list(df.project_name.unique())
    return file_names, project_names
# List of notebooks and corresponding project names
files, projects = load_file_project_names()
#Testing
files = files[5:8]
projects = projects[5:8]
directory_path = "./"
def convert_html_to_pdf(directory_path):
    # Ensure the output directory exists
    # output_directory = os.path.join(directory_path, 'sb1_cycle4_pdfs')
    # os.makedirs(output_directory, exist_ok=True)
    # Loop through HTML files in the input directory
    for filename in os.listdir(directory_path):
        if filename.endswith('.html'):
            html_file_path = os.path.join(directory_path, filename)
            
            # Generate PDF file path
            # pdf_file_path = os.path.join(output_directory, f"{os.path.splitext(filename)[0]}.pdf")
            pdf_file_path = f"{os.path.splitext(filename)[0]}.pdf"
            
            # Convert HTML to PDF using WeasyPrint
            HTML(string=open(html_file_path, 'r', encoding='utf-8').read()).write_pdf(pdf_file_path, presentational_hints=True)
            
            # Delete HTML file
            os.remove(html_file_path)
            print(pdf_file_path)
    
             # Move PDF to GCS
            bucket_name = 'calitp-analytics-data'
            blob_name = f'data-analyses/project_prioritization/2024_factsheets/PDF_scorecards/{pdf_file_path}'
            
            client = storage.Client()
            bucket = client.bucket(bucket_name)
            blob = bucket.blob(blob_name)
            blob.upload_from_filename(file_path)
            print(f"{pdf_file_path} uploaded to GCS")
            os.remove(pdf_file_path)
# Loop through notebooks and execute Papermill
for notebook, project in zip(files, projects):
    subprocess.run(["papermill", "explore_scorecard.ipynb", notebook, "-p", "one_project_test", project])
    
    # Trust all the notebooks
    subprocess.run(["jupyter", "trust", notebook])
    
    # Convert the output notebook to html
    subprocess.run(["jupyter", "nbconvert", notebook, "--to=html", f"--TemplateExporter.exclude_input=True"])
  
    # Convert html to pdfs - comment out now because explore doesn't work well with pdf
    convert_html_to_pdf(directory_path)
    
    # Delete notebooks
    file_path_to_delete = os.path.join(directory_path, notebook)
    os.remove(file_path_to_delete)