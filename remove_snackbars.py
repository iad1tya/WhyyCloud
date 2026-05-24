import os
import re

def remove_call(content, func_name):
    pattern = re.compile(func_name + r'\s*\(', re.DOTALL)
    while True:
        match = pattern.search(content)
        if not match:
            break
        start_idx = match.start()
        # find matching parenthesis
        paren_count = 1
        idx = match.end()
        while idx < len(content) and paren_count > 0:
            if content[idx] == '(':
                paren_count += 1
            elif content[idx] == ')':
                paren_count -= 1
            idx += 1
        # optionally eat whitespace and semicolon
        while idx < len(content) and content[idx] in ' \t\n\r':
            idx += 1
        if idx < len(content) and content[idx] == ';':
            idx += 1
        content = content[:start_idx] + content[idx:]
    return content

for root, _, files in os.walk('lib'):
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(root, f)
            with open(path, 'r') as file:
                content = file.read()
            original = content
            content = remove_call(content, r'Get\.snackbar')
            content = remove_call(content, r'ScaffoldMessenger\.of\(context\)\.showSnackBar')
            if content != original:
                with open(path, 'w') as file:
                    file.write(content)
