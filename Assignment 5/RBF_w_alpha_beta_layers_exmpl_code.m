%radial basis function network emulation using multilayer perceptrons
%starter code--needs completion and parameter tweaking

%fit two inputs to one output
%
clear all
load 'arm_x.txt' %data file containing columns of feature 1, feature 2 and targets
theta1=arm_x(:,1);
theta2=arm_x(:,2);
target_vals=arm_x(:,3);
temp=size(theta1);
npatterns = temp(1); %there are this many training patterns in the file
bias_inputs = ones(npatterns,1); %fake input node for bias--always outputs 1 for every pattern


%TUNING PARAMETERS

%use this many alpha-layer perceptrons 
nalpha = 1000;  %EXPERIMENT WITH THIS VALUE
%number of beta nodes must be less than number of training patterns
nbeta=20; %EXPERIMENT WITH THIS
bias_gain = .5
bias_eps = 1;
%END TUNING PARAMETERS


figure(1)
plot3(theta1,theta2,target_vals,'*') %take a look at the training data
title('display of training data')

[theta1, theta1_min, theta1_max] = scale_inputs(theta1);
[theta2, theta2_min, theta2_max] = scale_inputs(theta2);

ninputs=2; %theta1 and theta2, also weights from bias

%use tansig() activation function for alpha nodes

%initialize weights from inputs to alpha layer to random values:
%Use Random values
W_to_alpha_from_inputs = zeros(nalpha,ninputs+1); %FTFY
W_to_alpha_from_inputs(:,2:(ninputs+1)) = random('unif',-1,1,nalpha,ninputs);

for(j = 1:nalpha)
    bound = sum(abs(W_to_alpha_from_inputs(j,2:ninputs+1)));
    W_to_alpha_from_inputs(j,1) = random('unif',-bound,bound);
end

%Plot out alpha layer
figure(7)
clf
hold on
for j = 1:nalpha
    plot_perceptron(W_to_alpha_from_inputs(j,:));
end
plot(theta1, theta2, 'r*');
axis([-1 1 -1 1])
hold off

%initialize alpha-to-beta weights all to zero; include room for virtual
%bias alpha node; train these weights by imprinting
W_to_beta_from_alpha = zeros(nbeta,nalpha+1); %this is fine to start with

ngamma=1; %single output--use linear activation function, sigma=u
%initialize weights from beta layer to gamma (output) node:
%include room for virtual beta node bias input
W_to_gamma_from_beta = zeros(ngamma,nbeta+1); %need to learn these in the last step

%select patterns at random from training set to "imprint" weights into beta
%nodes.  Number of patterns to choose = number of beta nodes chosen
xtrain=zeros(nbeta,1);
ytrain=zeros(nbeta,1);
%choose beta-training points selected at random from training patterns
pat_list = zeros(nbeta,1);
for ibeta=1:nbeta
    %Randomly choose a pattern
    ipat = random('unid',npatterns);
    %If the pattern is already used, try again
    while ~isempty(find(pat_list==ipat ))
        ipat = random('unid',npatterns);
    end
    
    %Add the chosen pattern to the list of chosen patterns
    p_pick = ipat;
    
    xval = theta1(p_pick)
    yval = theta2(p_pick)
    xtrain(ibeta) = xval; %keep a record of the chosen training pattern values
    ytrain(ibeta) = yval;
    stim = [1;xval;yval]; %stimulate network at this set of inputs, including bias
    u_alphas = W_to_alpha_from_inputs*stim; %vector of alpha-node inputs
    sig_alpha = tansig(u_alphas); %outputs of alpha layer--not including bias node

    %on the basis of the alpha-node responses, choose how to select
    %weights leading into the ibeta'th beta node
    wvec = [0; (sign(sig_alpha)+1)/2]; %FTFY
    bias = -nalpha/2 + 260;%-sum(wvec)+253;%-[1;sig_alpha]' * wvec  + bias_eps;
    wvec(1) = bias;
    W_to_beta_from_alpha(ibeta,:) = wvec'; %install these weights leading into beta node  ibeta 
end
%debug--look response of each beta node over range of stimuli
%each beta-node response should look like a Gaussian.  If not, reexamine
%your choices in the preceding loop.  Choice of bias term is also crucial.
%comment out this debug code after confirming proper beta-node responses
figure(2)
clf;
for ibeta=1:nbeta
    ibeta;
    subplot(5,5,ibeta);
    ffwd_beta_surfplot(W_to_alpha_from_inputs,W_to_beta_from_alpha,ibeta)
    title('trained beta node response')
end


%now utilize all training data...
%compute outputs of alpha layer:
%u_alphas has nalpha rows (one for each node) and npatterns columns 
u_alphas = W_to_alpha_from_inputs*[bias_inputs';theta1';theta2'];
sig_alphas = tansig(u_alphas);
sig_alphas = [ones(1,npatterns );sig_alphas]; %insert virtual bias nodes in first row
       
%compute beta-node responses to all stimuli:
%beta-layer sigmas are in columns, one column per stimulus pattern
u_betas = W_to_beta_from_alpha*sig_alphas;
sig_betas = logsig(u_betas);
%sig_betas is nbeta rows of npat cols
%expand sig_betas to add a virtual extra node for bias:
sig_betas = [ones(1,npatterns);sig_betas]; %virtual beta node output = 1 for every stim

%call this F; 
F = sig_betas; %contains results of network simulations on all training inputs up through
 %beta-node outputs.  Still need to train gamma-node input weights--a row
 %vector

%want   target_vals' = w_vec*sig_betas
%need to match: target_vals' = w_vec*sig_betas = w_vec*F
% or, target_vals = F' * w_vec'
%or, w_vec' = F'\target_vals

%algebraic solution uses pseudoinverse to find  min-squared error solution for w_vec:

w_vec =F'\target_vals; %row vector of weights from beta to gamma
w_vec = w_vec'; %turn w_vec into a column vector

%simulate:
x_sim = w_vec*sig_betas; %row vector of outputs for each stimulus; this is as good as the
  %network gets, given choices for random alpha nodes and
  %selectively-trained beta nodes

%compute the sum squared error for simulation of all training data:
errvec = target_vals - x_sim';
Esqd_avg = norm(errvec)/npatterns;
rms_err = sqrt(Esqd_avg) %this is a measure of how well the network matches the
  %training values... units are same units as target values

%test--can look at network mapping results for subset of patterns chosen to
%imprint the beta nodes...nbeta = number of training samples
u_alphas = W_to_alpha_from_inputs*[ones(1,nbeta);xtrain';ytrain'];
sig_alphas=tansig(u_alphas);
sig_alphas=[ones(1,nbeta );sig_alphas]; %virtual bias nodes in first row
u_betas = W_to_beta_from_alpha*sig_alphas;
sig_betas=logsig(u_betas);
sig_betas = [ones(1,nbeta);sig_betas]; %virtual beta node output = 1 for every stim
z_train=w_vec*sig_betas;

%sample the network response for uniform scan over rectangular range:
xvals=[0:0.1:1]*range(theta1) + min(theta1); %choose to sample over a rectangular domain
yvals=[0:0.1:1]*range(theta2) + min(theta2);
imax = length(xvals);
jmax = length(yvals);
xpts=zeros(imax*jmax);
ypts=zeros(imax*jmax);
zpts=zeros(imax*jmax);
Z=zeros(11,11); %holder for 11x11 grid of outputsn
nsamps=0;
for (i=1:imax)
    for(j=1:jmax)
        nsamps=nsamps+1;
        xpt=xvals(i);
        ypt=yvals(j);
        xpts((i-1)*jmax+j) = xpt;
        ypts((i-1)*jmax+j) = ypt;
        stim = [1;xpt;ypt]; %stimulate network at this set of inputs, including bias
        u_alphas = W_to_alpha_from_inputs*[1;xpt;ypt];
        sig_alphas = [1; tansig(u_alphas)]; %outputs of alpha layer
        u_betas = W_to_beta_from_alpha*sig_alphas;
        sig_betas = [1;logsig(u_betas)]; %outputs of beta nodes
        gamma = w_vec*sig_betas;
        Z(j,i)= gamma;  %note: surf() demands swap indices!
        zpts((i-1)*jmax+j)=gamma;
    end
end


figure(3)
%plot3(theta1,theta2,target_vals,'*',theta1,theta2,x_sim,'x')
%plot3(theta1,theta2,target_vals,'*',theta1,theta2,x_sim,'x',xtrain,ytrain,z_train','o',xpts,ypts,zpts,'.')
plot3(theta1,theta2,target_vals,'*',xtrain,ytrain,z_train','o')

title('training points and beta-training subset response')

figure(4)
plot3(theta1,theta2,target_vals,'*',theta1,theta2,x_sim,'x',xtrain,ytrain,z_train','o',xpts,ypts,zpts,'.')
title('sample points and simulated function (surface)')
hold on;
surf(xvals,yvals,Z)
hold off;
axis([theta1_min-1, theta1_max+1, theta2_min-1, theta2_max+1, min(target_vals)-1, max(target_vals)+1])

%THIS CONCLUDES ALGEBRAIC APPROACH AND EVALUATION
%IMPLEMENT ALTERNATIVE SEARCH METHOD FOR W_to_beta_from_alpha
%USING RANDOM PERTURBATIONS
%ANALYZE RESULTS









