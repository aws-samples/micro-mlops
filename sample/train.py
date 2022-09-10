import os
import sys
import numpy as np
import pandas as pd
import sklearn as sk
import pickle as pkl

# variable names
names = [
    'sex',
    'length',
    'diameter',
    'height',
    'whole_weight',
    'shucked_weight',
    'viscera_weight',
    'shell_weight',
    'rings'
]

# reading dataset
df = pd.read_csv('data/abalone.data', header=None, names=names)

# building prediction target
df['target'] = (df['rings'] >= 10).astype(int)
df = df.drop('rings', axis=1)

# seperating target from features
y = np.array(df['target'])
X = df.drop('target', axis=1)

# shuffling and splitting data into training and test sets
from sklearn.model_selection import train_test_split

SPLIT = 0.33
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=SPLIT, random_state=42)

# one-hot encoding categorical features
CATEGORICALS = ['sex']
DUMMIES = {
    'sex':['M','F','I']
}

def dummy_encode(in_df, dummies):
    out_df = in_df.copy()
    
    for feature, values in dummies.items():
        for value in values:
            dummy_name = '{}__{}'.format(feature, value)
            out_df[dummy_name] = (out_df[feature] == value).astype(int)
            
        del out_df[feature]
        # print('Dummy-encoded feature\t\t{}'.format(feature))
    return out_df
        
X_train = dummy_encode(in_df=X_train, dummies=DUMMIES)

X_test = dummy_encode(in_df=X_test, dummies=DUMMIES)

X_train.head()

# rescaling numerical features
NUMERICS = ['length','diameter','height','whole_weight','shucked_weight','viscera_weight','shell_weight']
BOUNDARIES = {
    'length': (0.075000, 0.815000),
    'diameter': (0.055000, 0.650000),
    'height': (0.000000, 1.130000),
    'whole_weight': (0.002000, 2.825500),
    'shucked_weight': (0.001000, 1.488000),
    'viscera_weight': (0.000500, 0.760000),
    'shell_weight': (0.001500, 1.005000)
}

def minmax_scale(in_df, boundaries):
    out_df = in_df.copy()
    
    for feature, (min_val, max_val) in boundaries.items():      
        col_name = '{}__norm'.format(feature)
        
        out_df[col_name] = round((out_df[feature] - min_val)/(max_val - min_val),3)
        out_df.loc[out_df[col_name] < 0, col_name] = 0
        out_df.loc[out_df[col_name] > 1, col_name] = 1 
            
        del out_df[feature]
        # print('MinMax Scaled feature\t\t{}'.format(feature))
    return out_df
        
X_train = minmax_scale(in_df=X_train, boundaries=BOUNDARIES)

X_test = minmax_scale(in_df=X_test, boundaries=BOUNDARIES)

X_train.head()


from sklearn.ensemble import RandomForestClassifier

clf = RandomForestClassifier(
    n_estimators=100, # number of trees
    n_jobs=-1, # parallelization
    random_state=1337, # random seed
    max_depth=10, # maximum tree depth
    min_samples_leaf=10
)
model = clf.fit(X_train, y_train)


print( '------- Test Results -----------' )

# computing ROC AUC over training set
train_auc = sk.metrics.roc_auc_score(y_train, model.predict(X_train))
print('Training ROC AUC:\t', round(train_auc, 3))

# computing ROC AUC over test set
test_auc = sk.metrics.roc_auc_score(y_test, model.predict(X_test))
print('Test ROC AUC:\t\t', round(test_auc, 3))

pkl.dump(model, open('pickles/model_v1.pkl','wb'))

m = pkl.load(open('pickles/model_v1.pkl','rb'))

m
