%% Add path
% addpath(genpath('MM_testfunctions/'));
clear
clc

%% 不使用 Lasso/Relief/SU 预筛选，直接使用全部特征
% 直接读取数据获取特征数量
raw_data = readmatrix('王河山建模x.xlsx');
data = raw_data(:, 2:end); % 排除第一列序号
n_var = size(data, 2);
fprintf('使用全部 %d 个特征（无预筛选）。\n', n_var);

%% 生成固定的分层5折交叉验证划分
generate_cv_partition();
fprintf('已生成分层5折交叉验证划分。\n');

  tic
%   rand('state',sum(100*clock));
  global fname
   %chushi = [1,1,1,1,1,1,1,0,1,1,0,1,1,1,1,1,1,0,1,1,0 ,1,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1];
  
  % 动态设置 popsize：目标约 200，且必须是 n_var 的倍数
  % 这是因为某些遗传算子要求 popsize 能被 n_var 整除
  if n_var > 0
      multiplier = round(200 / n_var);  % 使用 round 让 popsize 更接近 200
      if multiplier < 1
          multiplier = 1;  % 至少是 1 倍
      end
      popsize = multiplier * n_var;
  else
      error('没有选中任何特征！');
  end
  fprintf('动态调整: n_var = %d, 倍数 = %d, popsize = %d\n', n_var, multiplier, popsize);

  Max_evaluation= 20000; 
  Max_Gen=fix(Max_evaluation/popsize);  % 朝0方向取整
  % Note: It may take a long time to run all 11 test functions and with   运行所有11个测试函数
  % population size 800 and generation 100. You can change N_function to 1,种群规模为800和100代。您可以将N_函数更改为1 
  %  popsize to 100, Max_evaluation to 1000, to see how the MO_Ring_PSO_SCD
  %  popsize为100，Max\u评估为1000，看看MO\u Ring\u PSO\u SCD如何
  %  works.

    fname='calculate_mean_fitness';
    n_obj=2;
    % n_var=25; 
    xl= zeros(1, n_var);
    xu= ones(1,n_var);
    % repoint = [2,2];
            
            
   fprintf('Running test function: %s \n', fname);
   %% Search the PSs using MO_Ring_PSO_SC
    [ps1,pf1,tempEXA]=newMO_Ring_PSO_SCD(fname,xl,xu,n_obj,popsize,Max_Gen);
%     writematrix(ps1,'PS1.csv');
%     writematrix(pf1,'PF1.csv');
    [ps,ps1sy,fsy] = unique(ps1,'row','stable'); % ps是把ps1去除重复后的剩余，ps1sy是ps1中非重复行的索引
%     writematrix(ps1sy,'PS1sy.csv');
%     [~,index] = sort(ps(:,2));
%     ps = ps(index,:);
    
    pf = pf1(ps1sy,:);   % 把非重复的ps对应的pf挑出来
%     pf = unique(pf,'row','stable'); 
    
    fprintf('  ps 已包含目标函数和特征\n');
    
    % 删除旧文件，确保完全覆盖
    if exist('4ps.xlsx', 'file')
        delete('4ps.xlsx');
    end
    if exist('4pf.xlsx', 'file')
        delete('4pf.xlsx');
    end
    if exist('tempEXA.xlsx', 'file')
        delete('tempEXA.xlsx');
    end
    
    writematrix(ps,'4ps.xlsx');
    writematrix(tempEXA,'tempEXA.xlsx');
    writematrix(pf,'4pf.xlsx');
    cd = size(ps,1);

   toc
   %% Plot figure
       % figure
       % 
       % plot(ps(1:cd,1),ps(1:cd,2),'*','Color',[0.19 0.8 0.19]);
       % hold on;
       % 
       % title ('PS');
       % 
       figure;

       plot(pf(1:cd,1),pf(1:cd,2),'.','Color',[1 0 0],'MarkerSize', 15);
       hold on;
       % plot(pf(1:cd,1), pf(1:cd,2), '-', 'Color', [0.19 0.8 0.19], 'LineWidth', 2); % 绘制连线
       xlabel('错误率（%）'); % 添加横坐标标签
       ylabel('特征个数'); % 添加纵坐标标签
%        plot(pf(81:380,1),pf(81:380,2),'r+');
%        hold on;
%        plot(pf(381:800,1),pf(381:800,2),'b+');
%        hold on;
       title ('PF (MMOFS - 基础版)');

   save('result.mat');
   save('tempEXA.mat', 'tempEXA');
