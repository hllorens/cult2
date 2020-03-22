#!/usr/bin/python

from __future__ import print_function

import sys,re,io

reload(sys)
sys.setdefaultencoding('utf-8')

with io.open(sys.argv[1],mode='r',encoding='utf8') as f:
	count=0;
	for line in f:
		linearr=line.split("\t")
		count=count+1
		if count is 1:
			maxp=int(linearr[0])
		popularity=(int(linearr[0])*10000)/maxp
		print(u'{}	{}'.format(popularity,linearr[1]), end="")
		#if count > 100:
		#	break

