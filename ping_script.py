#!/usr/bin/env python3
import requests
import time

def main():
    host = "daiquiri-loader"
    port = 10000
    
    average = 0
    num = 20
    for _ in range(num):
        t1 = time.perf_counter()
        response = requests.get("http://daiquiri-loader:10000/ping")
        t2 = time.perf_counter()
        average += (t2 - t1)
        print(f"Ping took {t2-t1} seconds")

    print(f"Average ping took {average/num} seconds")

main()
