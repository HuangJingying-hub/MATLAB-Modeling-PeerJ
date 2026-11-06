function pos = initial(Particle_Number, n_var)
% 初始化种群
% 生成 Particle_Number 个随机的二进制特征向量
% 每个向量至少有一个特征被选中

pos = zeros(Particle_Number, n_var);

for i = 1:Particle_Number
    % 随机决定选择多少个特征 (1 到 n_var)
    num_features = randi([1, n_var]);
    
    % 随机选择哪些特征
    selected = randperm(n_var, num_features);
    
    % 创建全零向量并设置选中的特征为1
    pos(i, selected) = 1;
end

end
