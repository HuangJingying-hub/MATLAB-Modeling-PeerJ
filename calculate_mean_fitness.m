function mean_fitness = calculate_mean_fitness(var)
% tic
    % rng(5)
    num_iterations=1;
    fitness_values = zeros(num_iterations, 2);
    for i = 1:num_iterations
        fitness = xgb_fitness(var); % 调用 XGBoost 适应度函数
        fitness_values(i, :) = fitness; % 存储 fitness 值

    end
    mean_fitness = mean(fitness_values,1); % 计算 fitness 均值
    % toc

end