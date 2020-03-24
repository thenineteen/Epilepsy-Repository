import pandas as pd
import numpy as np
from scipy.stats import chi2, chisquare, fisher_exact, chi2_contingency
from sklearn.metrics import matthews_corrcoef
from Stats.TheilsU import *

def performance_metrics(df, col, target, called_by_model_performance=False):
    """
    Setting Univariate Benchmarks using DataFrame
    col = feature we are intersted in (str)
    target = what we are predicting 
        - col of df as str
        - or can be of type pd.series/np.array
    df: rows= patients, cols = features

    Useful for benchmarks - no CI or std - static. 
    Marvasti Dec 2019
    """


    if type(target) != str:
        df[target.name] = np.nan
        df.loc[target.index, target.name] = target
        target=target.name

    if target == col:
        # checking two columns with same name in DataFrame, change names for convenience to avoid nan error:
        target = target+"_"
        # now can add as a duplicate column
        print("NB you are checking performance metrics with itself:")
        df[target] = np.nan
        df.loc[df[col].index, target] = df[col]



    no_of_pts_with_semiology_and_target_outcome = df.loc[df[col]==1, target].sum()
    total_with_semio = df.loc[df[col]==1, target].count()
    total_with_target = df.loc[df[target]==1, col].sum()
    total_patients = df.shape[0]

    col_y_target_y = no_of_pts_with_semiology_and_target_outcome
    col_y_target_n = total_with_semio - no_of_pts_with_semiology_and_target_outcome 
    # col_n_target_y = total_with_target - no_of_pts_with_semiology_gold
    col_n_target_y = df.loc[((df[target]==1)&(df[col]==0)), target].count()  # equivalent to .sum()
    col_n_target_n = df.loc[((df[target]==0)&(df[col]==0)), target].count()

    if called_by_model_performance==False:
        print('variable being tested: ', col, ' target: ', target)
        if col_y_target_n == (df.loc[((df[target]==0)&(df[col]==1)), target].count()) :
            print ('integrity check : pass')
        else: 
            print('oops major probelmo: not adding up. see source')
    

    OR_fisher, pv_fisher = fisher_exact(
        [
        [col_y_target_y, col_y_target_n],
        [col_n_target_y, col_n_target_n]
        ]         ) 
    
    try:
        OR_chi, pv_chi, _, _ = chi2_contingency(
            [
            [col_y_target_y, col_y_target_n],
            [col_n_target_y, col_n_target_n]
            ]         )
    except ValueError: 
        OR_chi = np.nan

    OR_manual = (col_y_target_y/col_y_target_n) / (col_n_target_y/col_n_target_n)


    SENS = col_y_target_y/(col_y_target_y+col_n_target_y)

    SPEC = col_n_target_n/(col_y_target_n+col_n_target_n)

    PPV = col_y_target_y/(col_y_target_y+col_y_target_n)

    NPV = col_n_target_n/(col_n_target_y+col_n_target_n)

    f1_score_target_y = 2*(SENS)*(PPV)/(SENS+PPV)

    f1_score_target_n = 2*(SPEC)*(NPV)/(SPEC+NPV)

    F1_MACRO = (f1_score_target_y+f1_score_target_n)/2

    BAL_ACC = (SENS+SPEC)/2

    ACCURACY_simple = (col_y_target_y+col_n_target_n)/(col_y_target_y+col_n_target_n+col_y_target_n+col_n_target_y)

    MCC = matthews_corrcoef(df[target], df[col])

    corr_test = associations(df[[col, target]], 
                          nominal_columns='all', mark_columns=False, Theils_U=True, plot=False,
                          return_results = True, 
                          savefigure=False,
                          title_auto=False)
    THEILSU = corr_test[col][target]
  
    metrics_OR = {'OR_fisher': OR_fisher, 'OR_chi':OR_chi ,  'OR_manual': OR_manual}
    metrics_classic = {'SENS':SENS, 'SPEC':SPEC, 'PPV':PPV, 'NPV':NPV, 'F1_MACRO':F1_MACRO,  'BAL_ACC':BAL_ACC, 
        'ACCURACY_simple':ACCURACY_simple, 'Matthews Correlation Coefficient':MCC, 'Theils U': THEILSU, 
        'Fisher p-value': pv_fisher}


    if called_by_model_performance==True:
        return F1_MACRO, BAL_ACC, ACCURACY_simple, SENS, SPEC, PPV, NPV, MCC, THEILSU

    else:    
        for i in metrics_OR.keys():
            print(i, metrics_OR[i])

        for j in metrics_classic.keys():
            print(j, metrics_classic[j])

        return