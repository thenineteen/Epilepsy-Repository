from sklearn.model_selection import RepeatedStratifiedKFold
from Stats.performance_metrics import *
import pandas as pd
import copy
from sklearn.model_selection import cross_val_score
from sklearn.metrics import make_scorer

def mean_std(cvs):
    print(cvs.mean(), cvs.std())



def model_performance_bootstrap(X, y, estimator, 
                      n_repeats = 20, n_splits = 2):
    """
    like performance_metric, but for the model, using RSKF CV. It has MCC and asymmetric Theils which cross_val_score 0.19.2 didn't.
    This uses static prediction of the model and bootstraps this. EStimator is RFECV so predict uses best fx.

    ---
    cf: below code which actually trains on 4 folds, and then predicts on 1 fold, 1000 times for differenct metrics. 
    This isn't so good as it uses the best_fx found from RFECV for a particular fold permutation, as RFECV didn't use RSKF. 
    rskf = RepeatedStratifiedKFold(n_splits=5, n_repeats=1000, random_state=1)
    top9features_rskf = cross_val_score(linear_svc, X_S_gold[best_fx], y_gold, cv=rskf, scoring='accuracy')
    top10HS_rskf = cross_val_score(linear_svc, X_HS_gold[best_fx_HS], y_gold, cv=rskf, scoring='accuracy')
    ---

    "FIXED 8" Jupyter notebook writes the first draft of this function, "FIXED 6" uses it. 

    

    n_repeats = 2
    n_splits = 5  # cv
    # estimator = linear_HS_EZ_RFECV_acc
    # performance_metrics_benchmarks()
    # X = X_SVC_pred
    # y = y_ESF_309
    # best_features = best_fx_HS_EZ
    """


    # initialise
    rskf = RepeatedStratifiedKFold(n_splits=n_splits, n_repeats=n_repeats, 
                                random_state=1)
    totals = np.zeros(n_repeats*n_splits)
    outcome = np.zeros(n_repeats*n_splits)
    # ali_list_metrics =  np.zeros(n_repeats*n_splits)
    F1_MACRO_list = np.zeros(n_repeats*n_splits)
    BAL_ACC_list = np.zeros(n_repeats*n_splits)
    ACCURACY_simple_list = np.zeros(n_repeats*n_splits)
    SENS_list = np.zeros(n_repeats*n_splits)
    SPEC_list = np.zeros(n_repeats*n_splits)
    PPV_list = np.zeros(n_repeats*n_splits)
    NPV_list = np.zeros(n_repeats*n_splits)
    MCC_list = np.zeros(n_repeats*n_splits)
    THEILSU_list = np.zeros(n_repeats*n_splits)
    i =0
    
    # static prediction of the entire train/cv set.
    SVC_prediction = estimator.predict(X)
    X_copy = copy.deepcopy(X)   
    X_copy['model'] = SVC_prediction

    # split the predicted classes via rskf udner for loop and calculate performance metrics:
    for train_index1, cv_index in rskf.split(X, y):

    #     # number in fold:
    #     number_in_fold = y_gold.iloc[cv_index].shape[0]
    #     totals[i] = number_in_fold
    # #     print(number_in_fold)
        
    #     # of which how many ESF:
    #     of_which_esf = (y_gold.iloc[cv_index].loc[y_gold==True]).shape[0]
    #     not_esf_naive = number_in_fold - of_which_esf  # needed for reverse naive prediction
    #     outcome[i] = not_esf_naive

        
        # rskf cv on the cv-index of the static prediction:
        F1_MACRO, BAL_ACC, ACCURACY_simple, SENS, SPEC, PPV, NPV, MCC, THEILSU = \
            performance_metrics(X_copy.iloc[cv_index], col='model', target=y.iloc[cv_index], called_by_model_performance=True)
        
        F1_MACRO_list[i], BAL_ACC_list[i], ACCURACY_simple_list[i], SENS_list[i],\
        SPEC_list[i], PPV_list[i], NPV_list[i], MCC_list[i], THEILSU_list[i] = \
            F1_MACRO, BAL_ACC, ACCURACY_simple, SENS, SPEC, PPV, NPV, MCC, THEILSU
        

        i+=1
        if (i%100 ==0): print(i)
            
        
    metric_names = ['F1_MACRO', 'BAL_ACC', 'ACCURACY_simple', 'SENS', 'SPEC', 'PPV', 'NPV', 'MCC', 'THEILSU']  
    metric_values = [F1_MACRO_list, BAL_ACC_list, ACCURACY_simple_list, SENS_list, SPEC_list, PPV_list, NPV_list, MCC_list, THEILSU_list]

    for i,j in zip(metric_names, metric_values):
        print(i, ':', mean_std(j), '\n')




def histogram_model_metric_HS_value(model, model_name,
                                    X_SoS, X_SoS_HS, y,
                                    best_fx, best_fx_HS, score=make_scorer(matthews_corrcoef)):
    """
    model = plain initialised model 
    """

    model_name='RF'
    X_SoS_color='lightgrey'
    X_SoS_HS_color='grey'

    rskf = RepeatedStratifiedKFold(n_splits=5, n_repeats=1000, random_state=1)

    model_rskf_mcc = cross_val_score(model, X_S_gold[best_fx], y_gold_binary, cv=rskf, scoring=score)
    model_rskf_mcc_HS = cross_val_score(model, X_HS_gold[best_fx_HS], y_gold_binary, cv=rskf, scoring=score)
    mean_std(model_rskf_mcc), mean_std(model_rskf_mcc_HS)


    plt.hist(model_rskf_mcc_HS, color=X_SoS_HS_color, label=model_name+' SoS+HS')   # mean = 0.41 mdeian = 0.55
    plt.hist(model_rskf_mcc, color=X_SoS_color,alpha=0.5, label=model_name+' SoS')  # mean = 0.24 mdeian = 0.17 

    if score==make_scorer(matthews_corrcoef):
        x_label = 'MCC'
    if score=='normalized_mutual_info_score':
        x_label = 'NMI avg'

    plt.xlabel(x_label)
    plt.ylabel('Frequency in 1000x5 CV')
    plt.legend()