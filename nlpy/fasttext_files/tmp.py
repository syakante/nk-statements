import fasttext

sh_ft = fasttext.load_model("ft_shield.bin")
#sh_ft.quantize(input=None, qout=False, cutoff=0, retrain=False, epoch=None, lr=None, thread=None, verbose=None, dsub=2, qnorm=False)
#ok dont quantize now it takes forever. just accept your out of ram lol.
#sw_ft = fasttext.load_model("ft_sword.bin")
#bd_ft = fasttext.load_model("ft_badge.bin")

def f():
	print("Example: find nearest neighbors of '핵억제력' in each model category")
	print("shield:")
	print(sh_ft.get_nearest_neighbors('핵억제력', k=10))
	print("sword:")
	print(sw_ft.get_nearest_neighbors('핵억제력', k=10))
	print("badge:")
	print(bd_ft.get_nearest_neighbors('핵억제력', k=10))

	print("Example: Find analogous words")
	print("e.g. 미국:핵무기::우리:___")
	print("In shield model:")
	print(sh_ft.get_analogies("핵무기", "미국", "우리"))
	print("In sword model:")
	print(sw_ft.get_analogies("핵무기", "미국", "우리"))
	print("In badge model:")
	print(bd_ft.get_analogies("핵무기", "미국", "우리"))