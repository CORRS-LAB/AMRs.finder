// Generated by using Rcpp::compileAttributes() -> do not edit by hand
// Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#include <RcppEigen.h>
#include <Rcpp.h>

using namespace Rcpp;

#ifdef RCPP_USE_GLOBAL_ROSTREAM
Rcpp::Rostream<true>&  Rcpp::Rcout = Rcpp::Rcpp_cout_get();
Rcpp::Rostream<false>& Rcpp::Rcerr = Rcpp::Rcpp_cerr_get();
#endif

// findMaxZ
IntegerVector findMaxZ(int s, int t, int mincpgs, const Eigen::MatrixXd& XS);
RcppExport SEXP _AMRfinder_findMaxZ(SEXP sSEXP, SEXP tSEXP, SEXP mincpgsSEXP, SEXP XSSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< int >::type s(sSEXP);
    Rcpp::traits::input_parameter< int >::type t(tSEXP);
    Rcpp::traits::input_parameter< int >::type mincpgs(mincpgsSEXP);
    Rcpp::traits::input_parameter< const Eigen::MatrixXd& >::type XS(XSSEXP);
    rcpp_result_gen = Rcpp::wrap(findMaxZ(s, t, mincpgs, XS));
    return rcpp_result_gen;
END_RCPP
}

static const R_CallMethodDef CallEntries[] = {
    {"_AMRfinder_findMaxZ", (DL_FUNC) &_AMRfinder_findMaxZ, 4},
    {NULL, NULL, 0}
};

RcppExport void R_init_AMRfinder(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
