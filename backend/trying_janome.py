from janome.tokenizer import Tokenizer
from janome.analyzer import Analyzer

t = Tokenizer()

test_string = 'お前はもう死んでいる'
for token in t.tokenize(test_string):
    print(str(token))

a = Analyzer()
for token in a.analyze(test_string):
    print(str(token))