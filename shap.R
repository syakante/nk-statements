library(keras)
#library(shapr)
library(kernelshap)
library(shapviz)
library(doMC)

sw.model <- load_model_hdf5("swordmodel.h5")
sh.model <- load_model_hdf5("shieldmodel.h5")
bd.model <- load_model_hdf5("badgemodel.h5")

set.seed(0)
registerDoMC(cores=8)

ind <- sample(nrow(M), 50)

small <- M[ind, ]

ks <- kernelshap(object = sw.model, X = M, bg_X = small)
sv <- shapviz(ks, X = M)

sh.ks <- kernelshap(object = sh.model, X = M, bg_X = small)
sh.sv <- shapviz(sh.ks, X = M)

bd.ks <- kernelshap(object = bd.model, X = M, bg_X = small)
bd.sv <- shapviz(bd.ks, X = M)

sv_importance(bd.sv, "both")
