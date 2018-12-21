clear, clc, close all;

counter = 0; % Set a counter at zero

for i = 96:-5:41;
    % For every iteration of the loop we will increase the counter by one
    counter = counter + 1; 
    
    % To read in a series of images we will use the sprintf function
    % in order to format an image string
    CT_Image_String = sprintf('PN-UU4062924-ST000-SE002-%04d.dcm', i);
    MS=[];
    
    % Because our images our .dcm files we will use dicomread to read in
    % the image string and imshow to show each image in the image string
    MS = dicomread(CT_Image_String);
    MS001 = imshow(MS, [], 'InitialMagnification','fit');
    
    % We will use imcrop to crop only the region of the CT including signal
    % from the DBS electrodes within the skull; this will prevent our code 
    % from detecting the skull as a border region
    % Simply select the region of the image with signal from the DBS
    % electrodes using the adjustable rectangle and right click selecting
    % "crop image" from the dropdown menu
    % Be careful not too include any of the skull while cropping!!
    MS001_crop = imcrop(MS001);
    
    % Convert the integer array “MS001_crop” to allow for decimal (floating 
    % point) numbers; this step will allow for automated object detection
    my_image = double(MS001_crop);
    
    % Normalize the image to set intensites between zero and one
    max_sub = max(my_image(:));
    min_sub = min(my_image(:));
    norm_image = (my_image - min_sub)./(max_sub-min_sub);
    
    % Create a binary image by replacing all values above a globally 
    % determined threshold with ones and setting all other values to zeros
    my_BW_image = imbinarize(norm_image, 0.9999);
    
    % Edge detection
    my_edge_det = edge(my_BW_image);
    
    % Label detected objects and identify the number of detected objects
    % with number_obj
    my_numbered_objects = bwlabel(my_edge_det);
    number_obj = max(my_numbered_objects(:));
    
    % Each image in the image string will have different signal 
    % intensities from corresponding DBS leads (i.e. the signal will be
    % much more intense near the distal lead at the region where the
    % active contacts are located); thus using the if, elseif, and else
    % commands we will specify the sensitivity factor to be used for 
    % adaptive thresholding to ensure that two objects (corresponding to
    % each DBS lead) are being identified for each image in our image
    % string
    if number_obj == 2;
        my_BW_image = imbinarize(norm_image, 0.9999);
        my_edge_det = edge(my_BW_image);
        my_numbered_objects = bwlabel(my_edge_det);
        number_obj = max(my_numbered_objects(:));
    elseif number_obj < 2;
        my_BW_image = imbinarize(norm_image, 0.99);
        my_edge_det = edge(my_BW_image);
        my_numbered_objects = bwlabel(my_edge_det);
        number_obj = max(my_numbered_objects(:));
        if number_obj == 2;
            my_BW_image = imbinarize(norm_image, 0.99);
            my_edge_det = edge(my_BW_image);
            my_numbered_objects = bwlabel(my_edge_det);
            number_obj = max(my_numbered_objects(:));
        else
            my_BW_image = imbinarize(norm_image, 0.9);
            my_edge_det = edge(my_BW_image);
            my_numbered_objects = bwlabel(my_edge_det);
            number_obj = max(my_numbered_objects(:));
        end
    else
        my_BW_image = imbinarize(norm_image, 0.999);
        my_edge_det = edge(my_BW_image);
        my_numbered_objects = bwlabel(my_edge_det);
        number_obj = max(my_numbered_objects(:));
    end
    
    % We will return the number of objects identified here for each
    % iteration of the for loop; this number should always be two,
    % corresponding to each DBS lead
    number_obj
    
    % Here we will compute the perimeter, area, and centroid of the
    % detected signal from the DBS leads
    STATS_peri = regionprops(my_numbered_objects, 'perimeter');
    STATS_area = regionprops(my_numbered_objects, 'area');
    STATS_centroids = regionprops(my_numbered_objects, 'centroid');
    
    % Using vertcat we will store the centroids of each DBS lead to an
    % array
    STATS_centroids_array = vertcat(STATS_centroids.Centroid);
    
    % Finally we will compute the distance between the centroids of each
    % detected signal produced from corresponding DBS leads
    D1 = (STATS_centroids_array(1, 1) - STATS_centroids_array(2, 1))^2;
    D2 = (STATS_centroids_array(1, 2) - STATS_centroids_array(2, 2))^2;
    Distance(counter) = sqrt(D1 + D2)
end

% We will plot the distances between DBS leads along the entire length of 
% the DBS lead, spanning from the distal electrode contacts to the point at
% which the proximal lead is capped within the skull
plot(Distance)
title('Separation of DBS Leads Implanted in Close Proximity')
xlabel('Distance from DBS Lead Distal Tip in Z-Direction (cm)');
ylabel('Distance Between DBS Leads in XY-Plane(mm)')
ylim([0 10]);

% Scale X-axis to Centimeters
xticks = get(gca,'xtick') 
scaling  = 1/2 
newlabels = arrayfun(@(x) sprintf('%.1f', scaling * x), xticks, 'un', 0)
set(gca,'xticklabel',newlabels)

