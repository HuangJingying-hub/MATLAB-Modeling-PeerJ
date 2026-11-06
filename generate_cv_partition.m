function generate_cv_partition()
%% 生成固定的分层5折交叉验证划分
% 被 newmain.m 调用，生成 cv_partition.mat
% 之后所有特征评估都使用同一套划分，确保公平比较

%% 读取标签数据
fprintf('读取标签数据...\n');
raw_Y = readmatrix('王河山建模y.xlsx', 'Range', 'B2');  % 跳过表头，从B2开始
Y = raw_Y(:, 1);  % 取第一列

% 移除可能的NaN
valid_idx = ~isnan(Y);
Y = Y(valid_idx);

n_samples = length(Y);
fprintf('有效样本数: %d\n', n_samples);

%% 检查类别分布
unique_labels = unique(Y);
fprintf('\n类别分布:\n');
for i = 1:length(unique_labels)
    count = sum(Y == unique_labels(i));
    fprintf('  类别 %g: %d 个 (%.1f%%)\n', unique_labels(i), count, count/n_samples*100);
end

%% 生成分层5折划分
fprintf('\n生成分层5折交叉验证划分...\n');
rng(42);  % 固定随机种子，确保可复现
cv = cvpartition(Y, 'KFold', 5, 'Stratify', true);
rng('shuffle');  % 恢复随机性，让PSO每次运行结果不同

%% 验证每折的类别分布
fprintf('\n验证每折的分布:\n');
for k = 1:5
    test_idx = test(cv, k);
    Y_test = Y(test_idx);
    n_test = sum(test_idx);
    n_class1 = sum(Y_test == 1);
    n_class2 = sum(Y_test == 2);
    fprintf('  折%d: %d个样本 (类1: %d=%.1f%%, 类2: %d=%.1f%%)\n', ...
        k, n_test, n_class1, n_class1/n_test*100, n_class2, n_class2/n_test*100);
end

%% 保存
save('cv_partition.mat', 'cv', 'valid_idx');
fprintf('\n✓ 已保存到 cv_partition.mat\n');
end
