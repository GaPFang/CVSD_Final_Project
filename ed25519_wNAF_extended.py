import random
q = pow(2,255)-19
q_inv = 21330121701610878104342023554231983025602365596302209165163239159352418617883 # q*q_inv % 2^255 = 2^255-1 = -1 mod 2^255
R = pow(2,255)%q
count_add_sub = 0
count_mul = 0

class number:
	def __init__(self, value: int):
		self.value = value # 255 bit

	def __add__(self, other: 'number') -> 'number': 
		r = self.value + other.value
		if(r>q):
			r -= q
		assert r == ((self.value + other.value) % q)
		global count_add_sub
		count_add_sub += 1
		return number(r)

	def __sub__(self, other: 'number') -> 'number':
		if(self.value >= other.value):
			r = self.value - other.value
		else:
			r = q - other.value
			r += self.value
		assert r == ((self.value - other.value) % q)
		global count_add_sub
		count_add_sub += 1
		return number(r)

	def MM(self,value1: int, value2: int) -> int: # Montgomery multiplication: (value1 * value2)>>255 mod q
		r = value1 * value2
		tmp = (((r%pow(2,255))*q_inv)%pow(2,255))*q
		r = (r + tmp)>>255
		if(r>=q):
			r -= q
		global count_mul
		count_mul += 1
		return r

	def __mul__(self, other: 'number') -> 'number': # mod mul: value1 * value2 mod q
		r = self.MM(self.value,R*R%q)
		r = self.MM(r,other.value)
		assert r == ((self.value * other.value) % q)
		return number(r)
	
	def inverse(self) -> 'number': # mod inv: value^(-1) mod q
		x = self.value
		k = 0
		Luv = 2*x
		Ruv = q
		Lrs = 1
		Rrs = 0
		while True:
			SLuv = (Luv < 0)
			SRuv = (Ruv < 0)
			hLuv = Luv >> 1
			k += 1
			if hLuv & 1 == 0:
				if (SLuv == (Luv > 0)):
					k -= 1
					break
				Luv = hLuv
				Rrs *= 2
			else:
				tmprs = Lrs
				Lrs = Lrs + Rrs
				if (SLuv ^ SRuv):
					Luv = hLuv + Ruv
				else:
					Luv = hLuv - Ruv
				if ((1 ^ SLuv) == (Luv < 0)):
					Ruv = hLuv
					Rrs = tmprs * 2
				else:
					Rrs *= 2
		Lrs -= Rrs
		if ((Lrs > 0)):
			Lrs += q
		while (k != 255):
			k -= 1
			if (Lrs & 1 == 0):
				Lrs = Lrs >> 1
			else:
				Lrs = (Lrs + q) >> 1
		return number(Lrs)
			

	def __truediv__(self, other: 'number') -> 'number': # mod div: value1 / value2 mod q
		inv = number(self.MM(other.value, R*R%q)).inverse().value
		return self * number(inv)

	def __neg__(self) -> 'number':
		return number(q-self.value)
	
	def __eq__(self, other: 'number') -> bool: 	# used for debug
		return self.value==other.value


d = number(0x52036cee2b6ffe738cc740797779e89800700a4d4141d8ab75eb4dca135978a3)
class point:
	def __init__(self, number_X: number, number_Y: number, number_Z: number = number(1), number_T: number | None = None):
		self.X = number_X
		self.Y = number_Y
		self.Z = number_Z
		self.T = number_T if number_T is not None else number_X*number_Y

	def __neg__(self) -> 'point':
		return point(self.X, -self.Y, self.Z, -self.T)

	def __add__(self, other: 'point') -> 'point':
		A = (self.Y-self.X)*(other.Y+other.X)
		B = (self.Y+self.X)*(other.Y-other.X)
		C = self.Z*number(2)*other.T
		D = self.T*number(2)*other.Z
		E = D+C
		F = B-A
		G = B+A
		H = D-C
		X3 = E*F
		Y3 = G*H
		T3 = E*H
		Z3 = F*G
		return point(X3,Y3,Z3,T3)
	
	def double(self) -> 'point':
		A = self.X*self.X
		B = self.Y*self.Y
		C = number(2)*self.Z*self.Z
		D = -A
		E = (self.X+self.Y)*(self.X+self.Y)-A-B
		G = D+B
		F = G-C
		H = D-B
		X3 = E*F
		Y3 = G*H
		T3 = E*H
		Z3 = F*G
		return point(X3,Y3,Z3,T3)

	def __mul__(self, M: int) -> 'point':
		w = 3

		P_double = self.double()
		tmp = self
		Ps = [tmp]
		for i in range(pow(2, w-2) - 1):
			tmp = tmp + P_double
			Ps.append(tmp)
		for i in range(pow(2, w-2)):
			Ps.append(-Ps[pow(2, w-2)-1-i])

		naf = toNAF(M, w)
		r = point(number(0), number(1))
		for i in range(len(naf) - 1, -1, -1):
			r = r.double()
			if(naf[i]!=0):
				r = r + Ps[naf[i] // 2]
		return r

	def reduce(self) -> 'point':
		x = self.X/self.Z
		y = self.Y/self.Z
		if(x.value%2==1): x.value = q-x.value
		if(y.value%2==1): y.value = q-y.value
		return point(x, y)
		
	def is_on_curve(self): # require self.Z=1
		return self.Y*self.Y-self.X*self.X == number(1) + d * self.X*self.X*self.Y*self.Y
	
	def __str__(self): # used for debug
		if(self.Z.value!=1):
			text = "The z-coordinate != 1"
		elif(self.is_on_curve()):
			text = "x: {:064x}\n".format(self.X.value) + "y: {:064x}\n".format(self.Y.value)
		else:
			text = "Invalid point"
		return text
	
def toNAF(x, w):
	naf = []
	while(x!=0):
		if(x%2==1):
			tmp = x%pow(2,w)
			naf.append(tmp)
			if (tmp < pow(2,w-1)):
				x -= tmp
			else:
				x -= (tmp - pow(2,w))
		else:
			naf.append(0)
		x = x//2
	return naf

if __name__ == "__main__":
	#testcase 1
	scalar_M = 0x259f4329e6f4590b9a164106cf6a659eb4862b21fb97d43588561712e8e5216a
	x = number(0x0fa4d2a95dafe3275eaf3ba907dbb1da819aba3927450d7399a270ce660d2fae)
	y = number(0x2f0fe2678dedf6671e055f1a557233b324f44fb8be4afe607e5541eb11b0bea2)

	#testcase 2
	# scalar_M = 0x17e0aa3c03983ca8ea7e9d498c778ea6eb2083e6ce164dba0ff18e0242af9fc3
	# x = number(0x2e2c9fbf00b87ab7cde15119d1c5b09aa9743b5c6fb96ec59dbf2f30209b133c)
	# y = number(0x116943db82ba4a31f240994b14a091fb55cc6edd19658a06d5f4c5805730c232)
	
	#testcase 3
	#scalar_M = 0x1759edc372ae22448b0163c1cd9d2b7d247a8333f7b0b7d2cda8056c3d15eef7
	#x = number(0x5b90ea17eaf962ef96588677a54b09c016ad982c842efa107c078796f88449a8)
	#y = number(0x6a210d43f514ec3c7a8e677567ad835b5c2e4bc5dd3480e135708e41b42c0ac6)

	point_P = point(x, y)
	point_G = (point_P * scalar_M).reduce()
	print("point P:")
	print(point_P)
	print("point G:")
	print(point_G)
	print("# of mod mul:",count_mul)
	print("# of mod add & sub:",count_add_sub)

