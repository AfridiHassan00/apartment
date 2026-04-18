import MySQLdb, getpass

pwd = getpass.getpass("MySQL root password: ")

conn = MySQLdb.connect(
    host="localhost",
    user="root",
    passwd=pwd,
    port=3306
)

cur = conn.cursor()
cur.execute("CREATE DATABASE IF NOT EXISTS exchange_db")
conn.commit()
conn.close()

print("OK")
