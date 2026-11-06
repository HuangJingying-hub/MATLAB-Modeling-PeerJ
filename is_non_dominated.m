function is_nd = is_non_dominated(candidate, population, n_var, n_obj)
    candidate_obj = candidate(n_var+1:n_var+n_obj);
    is_nd = true;
    for i = 1:size(population, 1)
        pop_obj = population(i, n_var+1:n_var+n_obj);
        if all(pop_obj <= candidate_obj) && any(pop_obj < candidate_obj)
            is_nd = false;
            return;
        end
    end
end
