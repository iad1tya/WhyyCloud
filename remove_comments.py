import os
import re

def strip_comments(text):
    string_pattern = r'([rR]?\'\'\'.*?\'\'\'|[rR]?\"\"\".*?\"\"\"|[rR]?\'[^\'\\]*(?:\\.[^\'\\]*)*\'|[rR]?\"[^\"\\]*(?:\\.[^\"\\]*)*\")'
    comment_pattern = r'(//[^\n]*|/\*.*?\*/)'
    
    pattern = re.compile(string_pattern + r'|' + comment_pattern, re.DOTALL | re.MULTILINE)
    
    def replacer(match):
        if match.group(1):
            return match.group(1)
        else:
            return ''
            
    text = pattern.sub(replacer, text)
    return text

for root, _, files in os.walk('lib'):
    for f in files:
        if f.endswith('.dart'):
            path = os.path.join(root, f)
            with open(path, 'r') as file:
                content = file.read()
            new_content = strip_comments(content)
            if new_content != content:
                with open(path, 'w') as file:
                    file.write(new_content)
