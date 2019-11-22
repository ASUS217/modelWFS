%%% Code used to correct focus by optimizing the total fluorescent signal.
%%% Feedback is the pixel intensity of images generated by scan image.

%% experiment parameters
n_frames = 1;           % number of frames used for signal averaging
wopt.p_steps = 8;       % Number of phase steps
N_diameter = 17;        % Number of SLM segments on circle diameter

%% set SLM block pattern
N = slm.setBlockGeometry(1, sopt.diameter, sopt.N_diameter, sopt.cx, sopt.cy);

%% use images produced by scan image as feedback
feedback = @() feedback_scanimage(hSI, n_frames);

%% create algorithm object
wavefront = zeros(N,1);             % initial wavefront
algorithm = Kubby_Hadamard(wopt.p_steps, wavefront);

%% perform wavefront shaping
[ideal_wavefront, t_set, WFSsignals] = WFS(slm, feedback, algorithm);
slm.setData(ideal_wavefront); slm.update;

%% store SLM pattern
grad_x = slm.get('GradientX');
grad_y = slm.get('GradientY');
slm.set('GradientX',0);
slm.set('GradientY',0);
slm.update;

% get image of optimized pattern on the SLM
optimized_pattern = double( flipud(slm.getPixels'))*2*pi/sopt.alpha;

%% save data
dirname = 'P:\TNW\BMPI\Projects\WAVEFRONTSHAPING\data\TPM\3rd gen\191122_WFScomparison_vs_depth_PDMSdiffuser\';
filename = ['d',num2str(d_nom,'%.3d'),'um_feedback.mat'];
save([dirname,filename],'ideal_wavefront','optimized_pattern','grad_x','grad_y','wopt','sopt','WFSsignals','N');