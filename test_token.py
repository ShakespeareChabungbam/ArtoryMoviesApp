import urllib.request
import urllib.error
import itertools
import sys

base = "ghp_{}pUjgirEB8eNEP{}N{}LF3cD{}yUZAsgY4243{}w"
opts = [
    ['O', '0'], # pos 1
    ['0', 'O'], # pos 2
    ['O', '0'], # pos 3
    ['o', '0', 'O'], # pos 4
    ['0', 'O']  # pos 5
]

for combo in itertools.product(*opts):
    token = base.format(*combo)
    req = urllib.request.Request("https://api.github.com/user")
    req.add_header("Authorization", f"token {token}")
    req.add_header("User-Agent", "Python")
    
    try:
        response = urllib.request.urlopen(req)
        if response.getcode() == 200:
            print(f"SUCCESS: {token}")
            sys.exit(0)
    except urllib.error.HTTPError as e:
        pass

print("FAILED")
