import sys
import re
import matplotlib.pyplot as plt
a = []
for line in sys.stdin:
	m = re.search(r'([\d\-\.]+)', line)
	if (m):
		a.append( float(m.group(1)) )

plt.plot(a)
plt.show()
