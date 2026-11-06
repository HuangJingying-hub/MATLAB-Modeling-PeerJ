function fitness=xgb_fitness(var)
% MMOFS 基础版本：不使用预筛选，直接使用全部特征

% 读取数据
raw_data = readmatrix('王河山建模x.xlsx', 'Range', 'B2');  % 从B2开始，跳过表头
data = raw_data;  % 已经是纯数据，无需再排除序号列

% 处理缺失值 (NaN) - 使用均值填充
for i = 1:size(data, 2)
    col = data(:, i);
    nan_mask = isnan(col);
    if any(nan_mask)
        col(nan_mask) = mean(col(~nan_mask));
        data(:, i) = col;
    end
end

% ===== 不加载预筛选特征，直接使用全部特征 =====
% 用 var 向量从全部特征中选择
X = data(:, var==1);

% 读取标签
raw_Y = readmatrix('王河山建模y.xlsx', 'Range', 'B2');  % 从B2开始，跳过表头
Y = raw_Y(:, 1);

% ===== 加载固定的分层5折交叉验证划分 =====
load('cv_partition.mat', 'cv');

% ===== 使用5折交叉验证=====
num_folds = 5;
fold_errors = zeros(num_folds, 1);

for k = 1:num_folds
    % 获取当前折的训练和测试索引
    train_idx = training(cv, k);
    test_idx = test(cv, k);
    
    p_train = X(train_idx, :);
    t_train = Y(train_idx);
    p_test = X(test_idx, :);
    t_test = Y(test_idx);
    
    N = sum(test_idx);
    
    % 训练 LogitBoost 模型 (Gradient Boosting)
    numTrees = 60;           % 树的数量
    maxDepth = 4;            % 树的最大深度
    learningRate = 0.1;      % 学习率
    
    t_template = templateTree('MaxNumSplits', 2^maxDepth - 1, 'MinLeafSize', 1);
    
    net = fitcensemble(p_train, t_train, ...
        'Method', 'LogitBoost', ...
        'NumLearningCycles', numTrees, ...
        'Learners', t_template, ...
        'LearnRate', learningRate);
    
    % 预测
    t_sim = predict(net, p_test);
    
    % 计算准确率
    accuracy = sum(t_sim(:) == t_test(:)) / N * 100;
    fold_errors(k) = 100 - accuracy;
end

% 计算5折的平均错误率（更稳定的估计）
avg_error = mean(fold_errors);

% 最终适应度 = 平均错误率
fitness_val = avg_error;

sum_of_f = sum(var);

fitness=[fitness_val, sum_of_f];
end
