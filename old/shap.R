library(keras)
#library(shapr)
library(kernelshap)
library(shapviz)
library(doMC)

sw.model <- load_model_hdf5("swordmodel2.h5")
sh.model <- load_model_hdf5("shieldmodel2.h5")
bd.model <- load_model_hdf5("badgemodel2.h5")

set.seed(0)
registerDoMC(cores=8)

#..? consistency? Is M here the training M or the test M? I'm pretty sure it's training
ind <- sample(nrow(M), 50)

small <- M[ind, ]
#small2 <- M2[ind,]

ks <- kernelshap(object = sw.model, X = M, bg_X = small)
sv <- shapviz(ks, X = M)

# ks2 <- kernelshap(object = sw.model, X = M2, bg_X = small2)
# sv2 <- shapviz(ks, X = M2)
#Don't do this.

sh.ks <- kernelshap(object = sh.model, X = M, bg_X = small)
sh.sv <- shapviz(sh.ks, X = M)

bd.ks <- kernelshap(object = bd.model, X = M, bg_X = small)
bd.sv <- shapviz(bd.ks, X = M)

sv_importance(sv, "both")

#? seeing if something about changing the features caused such changes in the SHAP, or if it was just randomnes..
#old.terms.v = read.table("features.txt", sep="\n") %>% getElement("V1")
