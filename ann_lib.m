function L = ann_lib()
L.load_concrete = @load_concrete;
L.init_params = @init_params;
L.loss_grad = @loss_grad;
L.train_adam = @train_adam;
% ... one handle per library function
end
function theta = init_params(layers, seed)
% ...
end
% In main_assignment2.m:
L = ann_lib();
[theta, hist] = L.train_adam(theta0, layers, Xtr, ytr, Xva, yva, opts);