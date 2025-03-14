%% Matlab setup -------------------------------------
clear all
close all

% MATLAB Objs
FC = FunctionContainer;

% MATLAB Params
Camera_Params = load("~/Documents/DTCS/MATLAB/Params/Left_Camera_Params.mat").Left_Camera_Params;
CalibParametersX = load("~/Documents/DTCS/MATLAB/Params/Calib_Params.mat").CalibParametersX;
CalibParametersY = load("~/Documents/DTCS/MATLAB/Params/Calib_Params.mat").CalibParametersY;

% MATLAB Vars
ComputationInfo = [0, (0.5), 0];
ComputationInfo(3) = 1/ComputationInfo(2);

% April Tag Info
TagInfo = ["tag36h11", 97, 1];

% Table Calib
Table = [1200, 600, 15]; % [Width, Height, Angle]
DvRange = [0, 800; 0, 280]; % Dx Dy Range
Scale(1) = Table(1) / (DvRange(1, 2)-DvRange(1, 1));
Scale(2) = Table(2) / (DvRange(2, 2)-DvRange(2, 1));

% ROS
rosshutdown
rosinit

%ROS
[Camera, CamError] = FC.ConnectToROSCameras();

%Dx = [1000, 200, 300, 400];
%Dy = [50, 200, 200, 200];

for i = 1:4
    TopicName = "/MATLAB/Cube" + string(i);
    ROSPublishers(i) = rospublisher(TopicName, "geometry_msgs/Point");
end
%FC.ROSPublish(ROSPublishers, Dx, Dy);

fprintf("\n--- Setup Complete ---\n")

%% Main Loop -------------------------------------
while (true)
    fprintf('\n--- ---\nCycle: %d \n', ComputationInfo(1));
   
    [Img, ROSError] = FC.GetROSImages(Camera);
    
    if (ROSError == 0)
        
        % Undistort
        UImg = undistortImage(Img, Camera_Params);
        
        % Tag Translations
        TagTranslations = FC.FindAprilTags(UImg, Camera_Params, TagInfo);

        % Get Displacements
        [Dx, Dy] = FC.ObjectDisplacements(TagTranslations);
        
        try
        % Calibrate Displacements
        [Dx, Dy] = FC.CalibrateDisplacements(Dx, Dy, Scale, CalibParametersX, CalibParametersY);

        % Publish
        FC.ROSPublish(ROSPublishers, Dx, Dy);

        % Print
        FC.PrintObjectDisplacements(Dx, Dy);
        catch ERROR
            disp("Nothing Found")
        end
        %Sleep ---------------
        %imshow(UImg);
        pause(ComputationInfo(3));
        ComputationInfo(1) = ComputationInfo(1) + 1;
    else
        fprintf("\nERROR - No Message Recieved\n")
    end
end

