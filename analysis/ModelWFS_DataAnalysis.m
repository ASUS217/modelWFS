%% Load saved stitched files (TPM frames with and without correction)
% This code analyze the data and generate maximum intensity  of the TPM
% 3D images before and after correction for scattering. 
% Final part plot the intensity as a fuction of depth.

close all

%% load stitched TPM image data
data_dirname = '';                      % add data directory here  
filename = 'TPM3D_StichedFiles.mat';    % filename stitched TPM data
load([data_dirname,filename]);

%% Parameters for converting TPM frames to correct dimensions in um
zoom = 30;                                                 % zoom factor from TPM scan image aquisition  
numPixels= 256;                                            % Pixels in TPM frame
resX = 512/(numPixels*zoom);                               % base x resolution of the image
resY = 512/(numPixels*zoom);                               % base y resolution
x_data= -(size(TPM3Dref,1)/2)*resX:resX:(size(TPM3Dref,1)/2)*resX;
y_data= -(size(TPM3Dref,2)/2)*resY:resY:(size(TPM3Dref,2)/2)*resY;

%% Depth parameters during TPM scanning(Objective piezo stage)
z=1:1:533;                                                                  % total z axis pixels
resZ=0.5;                                                                   % z-resolution
FStart=1;                                                                   % choose the frame to start with
dnom=40:20.5:306.5;                                                         % This distance is from the mean position of the PDMS surface. 
z_startframe=FStart*resZ;                                                   % z of starting frame in um
z_data=dnom(1)+(z_startframe:resZ:size(z,2)*resZ);                          % Relevant z_data for plotting and imaging
n_pdms=1.41;                                                                % PDMS refractive index
n_water=1.33;                                                               % Water refractive index
z_data=z_data*n_pdms/n_water;                                               % Original depth inside PDMS

%% Calculate Maximum Intensity projection
Nframes=size(TPM3Dref,1);                       % Number of frames selected for Max Intensity projection            
MaxIntensity_TPM3Dref=max(TPM3Dref(end/2+(-Nframes/2+1:Nframes/2),:,:),[],1);
MaxIntensity_TPM3Dfeedback=max(TPM3Dfeedback(end/2+(-Nframes/2+1:Nframes/2),:,:),[],1);
MaxIntensity_TPM3Dmodel=max(TPM3Dmodel(end/2+(-Nframes/2+1:Nframes/2),:,:),[],1);

%% Calculate the average bead intensity from each frame slice
%preallocation
Intensity_ref = zeros(size(TPM3Dref,3),1);
Intensity_feedback = zeros(size(TPM3Dfeedback,3),1);
Intensity_model = zeros(size(TPM3Dmodel,3),1);

% create moving average filter for detecting highest signal in image
Ns=10;                             % size of square considered when determining average intensity        
f = 1/(Ns^2).*ones(Ns,Ns);

for fn=1:size(TPM3Dref,3)
% consider intensity distribution of single slice
frame_ref = TPM3Dref(:,:,fn);
frame_feedback = TPM3Dfeedback(:,:,fn);
frame_model = TPM3Dmodel(:,:,fn);

% apply moving average filter to git rid of noise
F_ref = conv2(frame_ref,f,'same');
F_feedback = conv2(frame_feedback,f,'same');
F_model = conv2(frame_model,f,'same');

% take maximum signal in low-pass filtered image
Intensity_ref(fn) = max(F_ref(:));
Intensity_feedback(fn) = max(F_feedback(:));
Intensity_model(fn) = max(F_model(:));
end

%% Plot the 2D cross-section of intensities (Maximum Intensity projection)
A=squeeze(MaxIntensity_TPM3Dref(1,:,FStart:end));
B=squeeze(MaxIntensity_TPM3Dfeedback(1,:,FStart:end));
C=squeeze(MaxIntensity_TPM3Dmodel(1,:,FStart:end));

Imax_2 =max([A(:);B(:);C(:)]);
figure(1);colormap(hot); 
um = sprintf('(\x0B5m)');
subplot(1,3,1); imagesc(y_data,z_data, A',[0,Imax_2]);  ylabel(['Depth ' um]);  xlabel(['x ' um]); title('a');colorbar;axis on; set(gca,'FontSize',16);
subplot(1,3,2); imagesc(y_data,z_data,B',[0,Imax_2]);  ylabel(['z ' um]);  xlabel(['x ' um]); title('b');colorbar;axis off;set(gca,'FontSize',16);
subplot(1,3,3); imagesc(y_data,z_data,C',[0,Imax_2]); ylabel(['z ' um]);  xlabel(['x ' um]); title('c');colorbar ;axis off; set(gca,'FontSize',16);

%% Fit for the uncorrected and ModelWFS
%coefficients
a1=1.241e4;         % coefficient model data
a2=4.483e12;        % coefficient reference data
b=0.006783;         % coefficient in exponent
c=65.95;            % background intensity
d=96.95;            % depth offset

% fit_model
fit_model = a1*exp(-b*(z_data+d))+c;

% fit_model
fit_reference= a2*(z_data+d).^-4.*exp(-b*(z_data+d))+c;

Ibg = c;
%% Semilog plots of Intensity before and after correction
% plot properties
c_ref = [0, 0.4470, 0.7410];  % color reference data points
c_model = [1,0,0];            % color model data points
c_feedback = [0,0.8,0];       % color feedback data points
dark_blue = [0,0,0.8];        % fit reference data
dark_red = [.8,0,0];          % fit model data
lw = 2;

figure(2); clf;
p1= semilogy(z_data,Intensity_ref(:),'d','color',c_ref,'MarkerSize',12,'LineWidth',1.25);
hold on; p2= semilogy(z_data,Intensity_feedback(:),'s','color',c_feedback,'MarkerSize',12,'LineWidth',1.25);
hold on; p3= semilogy(z_data,Intensity_model(:),'o','color',c_model,'MarkerSize',12,'LineWidth',1.25);
D1=ones(1,size(z_data,2)).*double(Ibg);
hold on; p4= semilogy(z_data,D1(:),'black:','MarkerSize',20,'MarkerEdgeColor','black','LineWidth',3);
set(gca,'box','on');set(legend,'box','off')
xlim([z_data(1) 325]);ylim([4e1 1e4]);
hold on; p5= semilogy(z_data,fit_reference,'--','color',dark_blue,'LineWidth',lw);
hold on; p6= semilogy(z_data,fit_model,'--','color',dark_red,'LineWidth',lw);

set(gcf,'Position',[1388,799,1252,899]);
legend([p1 p2 p3 p4], {'No correction','Feedback-based','Model-based','Average background level'});set(gca,'FontSize',20);ylabel(['Intensity (counts)']);  xlabel(['Depth ' um]);
set(gca,'FontSize',24);
set(legend,'FontSize',22);