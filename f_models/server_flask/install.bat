rem Create virtual environment
py -3 -m venv venv
rem Activate virtual environment
call venv\Scripts\activate
rem Install dependencies
@echo on
pip install flask