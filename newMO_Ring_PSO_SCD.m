function [ps,pf,tempEXA]=MO_Ring_PSO_SCD(func_name,VRmin,VRmax,n_obj,Particle_Number,Max_Gen)


%% Initialize parameters 初始化参数
n_var=size(VRmin,2); % n_var 待改              % Obtain the dimensions of decision space 获取决策空间的维数  1是行数，2是列数
Max_FES=Max_Gen*Particle_Number;   %Maximum fitness evaluations 最大适应度评估
n_PBA=10;                           % Maximum size of PBA. PBA的最大尺寸。 该算法在不受PBA大小限制的情况下性能更好。但这很耗时。
n_NBA=3*n_PBA;                     % Maximum size of NBA NBA的最大尺寸。
cc=[2.05 2.05];                    %Acceleration constants 加速度常数
iwt=0.7298;                        %Inertia weight 惯性重量
%% Initialize particles' positions and velocities  初始化粒子的位置和速度
Vmin = -3 *ones(1,n_var);
Vmax = 3 *ones(1,n_var);
mv = rand(1,n_var);
pos = initial(Particle_Number,n_var);
vel=Vmin+2.*Vmax.*rand(Particle_Number,n_var);        %初始化粒子的速度   800*3矩阵
%% Evaluate the population  计算适应度值
fitness=zeros(Particle_Number,n_obj);  % 800*3矩阵
for i=1:Particle_Number
    fitness(i,:)=feval(func_name,pos(i,:)); %代入指定函数计算适应度值
end
fitcount=Particle_Number;            % 计算适应度值
particle=[pos,fitness];              %将位置和速度放在一个矩阵中 300*5 前三列是位置，后两列是两个适应度值
%% Initialize personal best archive PBA and Neighborhood best archive NBA  初始化个人最佳存档PBA和邻里最佳存档NBA
row_of_cell=ones(1,Particle_Number); % the number of row in each cell 每个单元格中的行数
col_of_cell=size(particle,2);        % 每个单元格中的列数  size(A,1),size(A,2),size(A,3) 分别为行数列数维度数
PBA=mat2cell(particle,row_of_cell,col_of_cell);  % 分成Particle_Number个元胞，每个元胞是 1行c列的矩阵
NBA=PBA;  % PBA中 每一行是位置和适应度值信息 300*5 前三列是位置，后两列是两个适应度值 300个元组

for i=1:Max_Gen
i    

    %% Update NBA
    for j=1:Particle_Number % 更新每个粒子的 邻域存档 NBA
        % Ring topology.  Particles exchange information with its closed neighbors 粒子与其近邻交换信息
        if j==1
            tempNBA=PBA{Particle_Number,:}; % 最后一个粒子的位置和适应度值信息   PBA是历史存档，NBA是邻域存档，是tempNBA排序后取的前一部分
            tempNBA=[tempNBA;PBA{1,:}];
            tempNBA=[tempNBA;PBA{2,:}];  % 如果j=1，把最后一个，第1,2粒子 三个元胞里的粒子信息 3*39矩阵
        elseif j==Particle_Number
            tempNBA=PBA{Particle_Number-1,:};
            tempNBA=[tempNBA;PBA{Particle_Number,:}];
            tempNBA=[tempNBA;PBA{1,:}];  %把倒数第二个，最后一个，第一个，三个粒子的信息,3*39矩阵
        else
            tempNBA=PBA{j-1,:};
            tempNBA=[tempNBA;PBA{j,:}];
            tempNBA=[tempNBA;PBA{j+1,:}]; % 把j的前一个，j本身，和j的下一个，三个粒子信息 3*39矩阵
        end
        NBA_j=NBA{j,1};   % 把j粒子加进去
        tempNBA=[tempNBA;NBA_j];  % 最后再并列一个j粒子到后面去 四行
        tempNBA=non_domination_scd_sort(tempNBA(:,1:n_var+n_obj), n_obj, n_var);  % 函数里的tempNBA是四行五列矩阵
        % Optional operation. Limit the size of NBA to save time.  可选操作。限制NBA的规模以节省时间。
        if size(tempNBA,1)>n_NBA    %如果行数大于15
            NBA{j,1}=tempNBA(1:n_NBA,:);   % 把 第j个元组，改成15行5列的矩阵 取前15个
        else        % NBA 是每个粒子的元组带着自身周围的一坨粒子
            NBA{j,1}=tempNBA;  % 否则 第j个 元胞等于tempNBA
        end
    end   % NBA 最少有四个粒子信息， 最多有15个
    % 每一个粒子都给它分配一坨粒子，NBA中的每个元组，代表一个粒子和它所带的一坨。
    
    
    for k=1:Particle_Number %更新每个粒子位置和每个粒子的历史存档PBA
        % Choose the first particle in PBA_k as pbest  选择PBA_k中的第一个粒子作为pbest
        PBA_k=PBA{k,1};       %     PBA_k包含粒子k的历史位置 PBA元组的元胞是粒子本身加粒子历史信息
        pbest=PBA_k(1,:);     % 选择第一个 个体最优等于它自己
        % Choose the first particle in NBA_k as nbest  选择NBA_k中的第一个粒子作为nbest
        NBA_k=NBA{k,:};      %  NBA中元胞有多个粒子，是粒子与它所带的一坨，非历史信息
        
        nbest=NBA_k(1,:);   % 生态位最优取第一个
        % Update velocities according to Eq.(5) 根据等式更新速度。
        vel(k,:)=iwt.*vel(k,:)+cc(1).*rand(1,n_var).*(pbest(1,1:n_var)-pos(k,:))+cc(2).*rand(1,n_var).*(nbest(1,1:n_var)-pos(k,:));
        % Make sure that velocities are in the setting bounds. 确保速度在设定范围内。
        vel(k,:)=(vel(k,:)>mv).*mv   +  (vel(k,:)<=mv).*vel(k,:);
        vel(k,:)=(vel(k,:)<(-mv)).*(-mv)+(vel(k,:)>=(-mv)).*vel(k,:);
        
        % 根据等式（4）更新位置
        %             pos(k,:)=pos(k,:)+vel(k,:);
        %         % 确保位置在设定范围内
        %             pos(k,:)=((pos(k,:)>=VRmin(1,:))&(pos(k,:)<=VRmax(1,:))).*pos(k,:)...
        %                 +(pos(k,:)<VRmin(1,:)).*(VRmin(1,:)+0.25.*(VRmax(1,:)-VRmin(1,:)).*rand(1,n_var))+(pos(k,:)>VRmax(1,:)).*(VRmax(1,:)-0.25.*(VRmax(1,:)-VRmin(1,:)).*rand(1,n_var));       
        for ig = 1:n_var
            sig = 1/( 1 + exp(-vel(k,ig)));
            r1 = rand;
            if sig > r1
                pos(k,ig)=0;
            else
                pos(k,ig)=1;
            end
            while sum(pos(k,:))==0
                pos(k,:)=randi([0, 1], 1, n_var);
            end
        end
        
        %   计算种群适应度值
        fitness(k,:)=feval(func_name,pos(k,1:n_var));
        fitcount=fitcount+1;
        particle(k,1:n_var+n_obj)=[pos(k,:),fitness(k,:)];  % 更新粒子信息 39维 =37维位置+2维目标函数



        %% Update PBA
        PBA_k=[PBA_k(:,1:n_var+n_obj);particle(k,:)];    % 把此粒子更新后粒子放进去 ，里面包含粒子现在位置和粒子历史位置
        PBA_k = non_domination_scd_sort(PBA_k(:,1:n_var+n_obj), n_obj, n_var); % 把粒子历史信息 按帕累托分层，拥挤度排序
        % Optional operation. Limit the size of PBA to save time. 可选操作。限制PBA的大小以节省时间。
        if size(PBA_k,1)>n_PBA
            PBA{k,1}=PBA_k(1:n_PBA,:);
        else
            PBA{k,1}=PBA_k;  % 里面所存粒子历史信息可以有很多个
        end
    end
    
    % if fitcount>Max_FES
    %     break;
    % end
    
end

%% 不使用 VNS 多样化增强 (MMOFSwithoutEFS 版本)
% 直接使用 PSO 优化后的 PBA 结果

%% Output ps and pf  输出帕累托最优解集和帕累托最优前沿
tempEXA=cell2mat(PBA);     % 将元胞数组转化为普通数组

tempEXA=tempEXA(:,1:n_var+n_obj);
uniqueRows = unique(tempEXA, 'rows');
tempEXA=uniqueRows;

tempEXA=non_domination_scd_sort(tempEXA(:,1:n_var+n_obj), n_obj, n_var);  % 按帕累托分层，然后每层按拥挤度排序
if size(tempEXA,1)>Particle_Number
    EXA=tempEXA(1:Particle_Number,:); %如果大于种群数，则取种群数量的粒子
else
    EXA=tempEXA;
end
% tempindex=find(EXA(:,n_var+n_obj+1)==1); % 原代码只选Rank 1

% 修改：保留 Rank 1 以及所有“Near-Pareto”解 (按特征数分组，误差容忍度 2%)
% 限制：只针对 Rank 1 中出现的特征数进行 Near-Pareto 筛选
% 1. 找出所有 Rank 1 的解
% 步骤1：找出所有 Rank 1 的解（真正的帕累托前沿）
rank1_indices = find(EXA(:, n_var+n_obj+1) == 1);
tempindex = rank1_indices;

tolerance = 0.5;
all_objs = EXA(:, n_var+1:n_var+n_obj);
all_errors = all_objs(:, 1);
all_feats = all_objs(:, 2);

% 获取 Rank 1 相关信息
rank1_objs = EXA(rank1_indices, n_var+1:n_var+n_obj);
rank1_errors = rank1_objs(:, 1);
rank1_feats = rank1_objs(:, 2);

% 只遍历 Rank 1 里出现过的特征数（这些才是帕累托前沿上的特征数量级）
unique_rank1_feats = unique(rank1_feats);
for f = unique_rank1_feats'
    % 找到该特征数在 Rank 1 中的最低错误率（这是帕累托前沿上的标杆）
    rank1_feat_mask = (rank1_feats == f);
    min_err = min(rank1_errors(rank1_feat_mask));
    
    % 在整个种群中找该特征数下，误差在 min_err + tolerance 以内的解
    current_feat_indices = find(all_feats == f);
    current_feat_errors = all_errors(current_feat_indices);
    
    valid_mask = current_feat_errors <= min_err + tolerance;
    valid_indices = current_feat_indices(valid_mask);
    
    tempindex = [tempindex; valid_indices];
end

tempindex = unique(tempindex); % 去重索引
% tempindex = 1:size(EXA, 1); % 返回所有解以保留多样性
% tempindex = find(EXA(:, n_var + n_obj + 1) == 1 | EXA(:, n_var + n_obj + 1) == 2);
jmq=EXA(tempindex,1:n_var); % 解码前（决策变量）

%---------------使用已存储的适应度值，不再重新评估---------------
% 重要修复：之前的代码会重新调用 feval(func_name,...) 评估每个解
% 但由于现在采用5次随机划分取平均，每次评估会得到不同结果！
% 这导致解的错误率在输出时发生变化，造成排序混乱和解丢失

% 直接使用 EXA 中已经存储的目标函数值（在优化过程中计算并保存的）
jmh = [EXA(tempindex, n_var+1:n_var+n_obj), jmq];  % [目标函数值, 决策变量]

% 原代码（已弃用，因为会导致5次平均时结果不一致）：
% for ii = 1:length(jmq(:,1))
%     xx=feval(func_name,jmq(ii,:));
%     jmh(ii,:)=[xx jmq(ii,:)];  %解码后
% end

%————————
ps=jmh; 

pf=EXA(tempindex,n_var+1:n_var+n_obj);
end



function f = non_domination_scd_sort(x, n_obj, n_var)  %非支配 scd排序  两个功能，分层，然后按拥挤度从小到大排序好。
% non_domination_scd_sort:  sort the population according to non-dominated relationship and special crowding distance
% 非支配scd_排序：根据非支配关系和特殊拥挤距离对种群进行排序
%% Input：

%                      Dimension                      Description
%      x               num_particle x n_var+n_obj     population to be sorted
%      n_obj           1 x 1                          目标空间维数
%      n_var           1 x 1                          决策空间维数

%% Output:
%              Dimension                                  Description
%      f       N_particle x (n_var+n_obj+4)               Sorted population
%    in f      the (n_var+n_obj+1)_th column stores the front number
%              the (n_var+n_obj+2)_th column stores the special crowding distance
%              the (n_var+n_obj+3)_th column stores the crowding distance in decision space
%              the (n_var+n_obj+4)_th column stores the crowding distance in objective space


[N_particle, ~] = size(x);% Obtain the number of particles 获取粒子数

% Initialize the front number to 1. 将前面的数字初始化为1。
front = 1;

% There is nothing to this assignment, used only to manipulate easily in 这个作业没有任何内容，只用于在
% MATLAB.
F(front).f = [];
individual = [];

%% Non-Dominated sort.
n_obj1 = n_obj;
n_var1 = 2;
for i = 1 : N_particle
    % Number of individuals that dominate this individual 控制该个体的个体数量
    individual(i).n = 0;
    % Individuals which this individual dominate   这个个体支配的个体
    individual(i).p = [];
    
    for j = 1 : N_particle
        dom_less = 0;
        dom_equal = 0;
        dom_more = 0;
        for k = 1 : n_obj1
            if (x(i,n_var + k) < x(j,n_var + k))   %目标函数小 就加1
                dom_less = dom_less + 1;
            elseif (x(i,n_var+k) == x(j,n_var+k))
                dom_equal = dom_equal + 1;
            else
                dom_more = dom_more + 1;   %目标函数大 加1
            end
        end
        
        if dom_less == 0 && dom_equal ~= n_obj1  % 两个函数，一个比我小，一个等于我或者两个都比我小的情况下，加1
            individual(i).n = individual(i).n + 1;  %比第i个粒子小的粒子数
        elseif dom_more == 0 && dom_equal ~= n_obj1  %两个函数，一个比我大，一个等于我或者两个都比我大的情况下，把粒子存进去
            individual(i).p = [individual(i).p j]; % 比第i个大的粒子的粒子编码
            
        end
    end
    if individual(i).n == 0      % 如果没有比我小的粒子 i粒子的最后一列设为1  其余九十九个有比我大的，有比我一大一小的
        x(i,n_obj + n_var + 1) = 1;
        F(front).f = [F(front).f i]; % 把i粒子加到前沿里 前沿里都是最小的 前沿里是 一个比我大，一个比我小的粒子
    end   % a粒子是帕累托前沿，原始种群中并非所有比a一大一小的粒子都能进帕累托前沿
end                                                                                                                                 %此处会造成重复，想办法避免
% Find the subsequent fronts  找到后续前沿
while ~isempty(F(front).f)  %数组为空，返回1  若不为空一直循环
    Q = [];
    for i = 1 : length(F(front).f) % 遍历所有前沿粒子
        if ~isempty(individual(F(front).f(i)).p) % 比这个前沿粒子大的 粒子集合不是空的 执行下面（又粒子比这个粒子大）
            for j = 1 : length(individual(F(front).f(i)).p)   %遍历所有比这个粒子大的粒子
                individual(individual(F(front).f(i)).p(j)).n = ... %比前沿粒子大的粒子的 比自身小的粒子数
                    individual(individual(F(front).f(i)).p(j)).n - 1;
                if individual(individual(F(front).f(i)).p(j)).n == 0
                    x(individual(F(front).f(i)).p(j),n_obj + n_var + 1) = ... %比前沿粒子大的这个粒子的最后一列加1
                        front + 1;
                    Q = [Q individual(F(front).f(i)).p(j)];  %把比前沿粒子大的这个粒子加到Q
                end
            end
        end
    end
    front =  front + 1;   % x的最后一列是前沿层数
    F(front).f = Q; %第二层，第一层最小   F里面是粒子索引 无粒子信息
end
% Sort the population according to the front number  根据前面的数字对人口进行排序
[~,index_of_fronts] = sort(x(:,n_obj + n_var + 1));  %按最后一列，即前沿层数排列，并返回索引
for i = 1 : length(index_of_fronts)
    sorted_based_on_front(i,:) = x(index_of_fronts(i),:);
end   % 结果是 按前沿层数从小到大排列好的 所有粒子信息， 粒子位置和函数值
current_index = 0;

%% SCD. Special Crowding Distance 特殊拥挤距离

for front = 1 : (length(F) - 1)  %遍历所有层
    
    crowd_dist_obj = 0;
    y = [];
    previous_index = current_index + 1; %每循环一次加1
    for i = 1 : length(F(front).f)  %遍历第一层前沿
        y(i,:) = sorted_based_on_front(current_index + i,:);% 把第front层所包含粒子的粒子信息都放到y中 此层里面有几个 y就有几个
    end
    current_index = current_index + i; % 此时i等于第一层的层数，后面再加就是第二层
    % Sort each individual based on the objective  基于目标值进行排序
    sorted_based_on_objective = [];

    gs = size(y,1);
    diyi = y(randi(gs),1:n_var);
    for i = 1:gs
        y(i, n_var+n_obj+2) = length(find(xor(y(i,1:n_var),diyi)==1));
    end
    [sorted, index] =  sort(y(:,n_var+n_obj+2));   % sorted是距离，index是索引
    sorted = y(index,:);
    y(index(1), n_var+n_obj+3)=0;
    y(index(length(index)), n_var+n_obj+3)=1;
    for j = 2 : length(index) - 1
        next_obj  = sorted(j + 1, 1:n_var);
        previous_obj  = sorted(j - 1,1:n_var);
        zishen_obj = sorted(j ,1:n_var);
        y(index(j), n_var+n_obj+3) = ...
            (length(find(xor(next_obj,zishen_obj)==1)) +length(find(xor(zishen_obj,previous_obj)==1)) )/(length(index)-2);
%             length( find( xor(next_obj,previous_obj )==1)) /8;
             %42列是层数  43，44是开关拥挤度，45,46是函数拥挤度
        %          
    end

    for i =n_var+ 1 : n_obj+n_var   %把位置，和函数值都进行排序    38 到 41
        [sorted_based_on_objective, index_of_objectives] = ...
            sort(y(:,i));      % 粒子的第i列进行排序
        sorted_based_on_objective = [];
        for j = 1 : length(index_of_objectives)
            sorted_based_on_objective(j,:) = y(index_of_objectives(j),:);
        end % sorted_based_on_objective 是把y按i列从小到大排序的矩阵 粒子只是此层的一部分
        f_max = ...
            sorted_based_on_objective(length(index_of_objectives), i);
        f_min = sorted_based_on_objective(1,  i);
        
        if length(index_of_objectives)==1
            y(index_of_objectives(1),n_obj  + 1 + i) = 1;  % 如果当前前沿只有一个点，那没得比不管它是位置还是函数拥挤度都是1
        elseif  i > n_var && i < n_obj+n_var-1  % 如果这一列是函数
            % deal with boundary points in objective space 处理目标空间中的边界点
            % In minimization problem, set the largest distance to the low boundary points and the smallest distance to the up boundary points
            % 在最小化问题中，设置到低边界点的最大距离和到上边界点的最小距离
            y(index_of_objectives(1),n_obj  + 1 + i) = 1; % 第一个粒子设置为1
            y(index_of_objectives(length(index_of_objectives)),n_obj  + 1 + i)=0; % 最后粒子设置为0
        else
            % deal with boundary points in decision space
            % 处理决策空间中的边界点
            % twice the distance between the boundary points and its nearest neibohood
            % 边界点与其最近邻居之间距离的两倍
            y(index_of_objectives(length(index_of_objectives)),n_obj  + 1 + i)...
                = 2*(sorted_based_on_objective(length(index_of_objectives), i)-...
                sorted_based_on_objective(length(index_of_objectives) -1, i))/(f_max - f_min);
            y(index_of_objectives(1),n_obj  + 1 + i)=2*(sorted_based_on_objective(2, i)-...
                sorted_based_on_objective(1, i))/(f_max - f_min);
        end
        for j = 2 : length(index_of_objectives) - 1
            next_obj  = sorted_based_on_objective(j + 1, i);
            previous_obj  = sorted_based_on_objective(j - 1,i);
            if (f_max - f_min == 0)
                y(index_of_objectives(j),n_obj  + 1 + i) = 1;
            else
                y(index_of_objectives(j),n_obj  + 1 + i) = ...
                    (next_obj - previous_obj)/(f_max - f_min);
            end  % 此时的y是算好的拥挤度
        end

    end  % 把位置，函数值都分别排了序，算了距离   粒子按前沿的排序,位置没变，计算出了所有的拥挤度，拥挤度是暂时排序，并没有变动排序位置
    %% Calculate distance in decision space
    
    % 计算目标空间中的距离
    crowd_dist_obj = [];
    crowd_dist_obj(:,1) = zeros(length(F(front).f),1);
    for i = 1 : n_obj1
        crowd_dist_obj(:,1) = crowd_dist_obj(:,1) + y(:,n_obj + n_var + 1 + i  );
    end
    crowd_dist_obj=crowd_dist_obj./n_obj1;   %是 第front层的粒子，的拥挤度，没有按拥挤度排序
    crowd_dist_obj = normalize(crowd_dist_obj,'range');
    avg_crowd_dist_obj=mean(crowd_dist_obj);   % 每列元素的均值


    %% Calculate special crowding distance
    %计算特殊拥挤距离
    % special_crowd_dist=zeros(length(F(front).f),1);  %几行1列
    % for i = 1 : length(F(front).f)
    %     if crowd_dist_obj(i)>avg_crowd_dist_obj||crowd_dist_var(i)>avg_crowd_dist_var
    %         special_crowd_dist(i)=max(crowd_dist_obj(i),crowd_dist_var(i)); % Eq. (6) in the paper
    %     else
    %         special_crowd_dist(i)=min(crowd_dist_obj(i),crowd_dist_var(i)); % Eq. (7) in the paper
    %     end
    % end
    % y(:,n_obj + n_var + 2) = special_crowd_dist;     % n_obj + n_var + 2
    % y(:,n_obj+n_var+3)=crowd_dist_var;
    y(:,n_obj+n_var+2)=crowd_dist_obj;
    %[~,index_sorted_based_crowddist]=sort(special_crowd_dist,'descend');%sort the particles in the same front according to SCD 根据SCD对同一前沿的粒子进行排序
    [~,index_sorted_based_crowddist]=sort(crowd_dist_obj,'descend');
    y=y(index_sorted_based_crowddist,:); % y 是按从大到小列排序的 按特殊拥挤距离重新排列的
    y = y(:,1 : n_obj + n_var+2 );
    z(previous_index:current_index,:) = y;  % 结果为 front层 按拥挤度重新排序后的结果 ，每层从大到小排序
    
end

f = z();

end



%Write by Caitong Yue 2017.09.04
%Supervised by Jing Liang and Boyang Qu
