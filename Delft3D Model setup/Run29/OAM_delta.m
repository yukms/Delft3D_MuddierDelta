h=bed_l(ii,:,:);
% close all

h0 = Sea_level(ii); OA0 = 70; L0 = 500; dx0 = 25; dx = 5;
h=squeeze(h);
h = h';

% % Remove NaN values around the matrix periphery
% h = h(2:size(h, 1) - 1, 2:size(h, 2) - 1);
% figure,imagesc(h)
% % Remove river L0
% idx = ceil(L0 / dx0 - 0.5) + 1;
% h = h(:, idx:size(h, 2));
% figure,imagesc(h)

% 2D interpolation
% [x0, y0] = meshgrid(1:size(h, 2), 1:size(h, 1));
% [x, y] = meshgrid(1:0.2:size(h, 2), 1:0.2:size(h, 1));  % Increase resolution by 5 times
% h = interp2(x0, y0, h, x, y, 'linear');  % 2D linear interpolation

% Divide the analysis area into land and water based on water depth
Lbw = h > h0; % Land
Wbw = ~Lbw;  % Water

% Find the largest connected water region as the new water area and calculate the new land area (remove water surrounded by land)
imlabel = bwlabel(Wbw);
stats = regionprops(imlabel, 'Area');
area = cat(1, stats.Area);
index = find(area == max(area));
W_out = ismember(imlabel, index);  % New water area for subsequent calculations
ind_W = find(W_out == 1);  % Water points' index
Lbw = ~W_out;  % New land area for subsequent calculations
ind_L = find(Lbw == 1);  % Land points' index

% Calculate the minimum convex polygon surrounding the land
[Ly, Lx] = find(Lbw == 1);  % Land points' coordinates, rows are y-coordinates, columns are x-coordinates
dt = DelaunayTri(Lx, Ly);
k = convexHull(dt);
Lcx = Lx(k); Lcy = Ly(k);  % Coordinates of the obtained convex polygon
ind_Lc = sub2ind(size(Lbw), Lcy, Lcx);  % Index of convex polygon points

% Calculate water outside the convex polygon as open water
[Wy, Wx] = find(W_out == 1);  % Water points' coordinates
ind_in = inpolygon(Wx, Wy, Lcx, Lcy);  % Index of water points inside the convex polygon
ind_W_out_in = sub2ind(size(W_out), Wy(ind_in), Wx(ind_in));  % Index of water points inside the convex polygon
ind_W_out_open = sub2ind(size(W_out), Wy(~ind_in), Wx(~ind_in));  % Index of water points outside the convex polygon (open water)

% Find the outer (inner) boundary of water, as the water-land boundary
se = strel('square', 3);
% I = imdilate(W_out, se) - W_out;  % Outer boundary of water, water-land boundary points, all points belong to land
I = W_out - imerode(W_out, se);  % Inner boundary of water, water-land boundary points, all points belong to water
[Iy, Ix] = find(I == 1);  %
ind_I = find(I == 1);  %

% Find land points on the image boundary
Lex1 = find(Lx == 1); Lex2 = find(Lx == size(Lbw, 2));  % Left and right boundaries
Ley1 = find(Ly == 1); Ley2 = find(Ly == size(Lbw, 1));  % Upper and lower boundaries

% Find Q set and T set
Qx = [Wx(ind_in); Ix]; Qy = [Wy(ind_in); Iy]; % Q coordinates
ind_Q = sub2ind(size(W_out), Qy, Qx);  % Index of Q points
Tx = [Ix; Lx(Lex1); Lx(Lex2); Lx(Ley1); Lx(Ley2)];  % T's x-coordinates (columns)
Ty = [Iy; Ly(Lex1); Ly(Lex2); Ly(Ley1); Ly(Ley2)];  % T's y-coordinates (rows)
ind_T = sub2ind(size(W_out), Ty, Tx);  % Index of T points

% Add a bank column on the T set
Tx_bank = -1 * ones(size(Lbw, 1), 1);
Ty_bank = (1:length(Tx_bank))';
Tx = [Tx; Tx_bank];
Ty = [Ty; Ty_bank];

% Calculate the open angle of points in the Q set
OA = zeros(size(W_out));
for i = 1:length(Qx)
    OA_temp = zeros(1, length(Tx));
    for j = 1:length(Tx)
        Q0x = Qx(i); Q0y = Qy(i);
        T0x = Tx(j); T0y = Ty(j);
        if Q0x == T0x
            if Q0y < T0y
                OA_temp(j) = 90;
            elseif Q0y > T0y
                OA_temp(j) = 270;
            else
                OA_temp(j) = 0;
            end
        elseif Q0y == T0y
            if Q0x < T0x
                OA_temp(j) = 0;
            else
                OA_temp(j) = 180;
            end
        else
            OA_tan = atan((Q0y - T0y) / (Q0x - T0x)) * 180 / pi;
            if OA_tan > 0
                if Q0x < T0x
                    OA_temp(j) = OA_tan;
                else
                    OA_temp(j) = OA_tan + 180;
                end
            elseif OA_tan < 0
                if Q0x < T0x
                    OA_temp(j) = OA_tan + 360;
                else
                    OA_temp(j) = OA_tan + 180;
                end
            end
        end
    end
    OAs = sort(OA_temp);
    dOA = zeros(1, length(OAs));
    for k = 1:length(OAs) - 1
        dOA(k) = OAs(k + 1) - OAs(k);
    end
    dOA(length(OAs)) = 360 - OAs(length(OAs)) + OAs(1);
    dOA = sort(dOA, 'descend');
    OA(Qy(i), Qx(i)) = dOA(1) + dOA(2) + dOA(3);
end

% Calculate the binary image of OA corresponding to the critical angle
OAc = OA;
OAc(ind_W_out_open) = 180;  % Define OA for open water as 180
OAc(OAc > 180) = 180;  % Set points greater than 180 to 180
OAbw = OAc;
OAbw = OAbw >= OA0;  % Binary image

% Find the largest connected region greater than OA0 and remove potentially isolated areas at the boundary
imlabel = bwlabel(OAbw);
stats = regionprops(imlabel, 'Area');
area = cat(1, stats.Area);
index = find(area == max(area));
OAbw = ismember(imlabel, index);

% % Depending on the situation, you may want to perform Gaussian blur
% [SLs SL_h]=contour(OAbw,[1 1]);  % Create a contour plot of the binary image
% SLs_num=SLs(2,1);  % Get the number of points in the first contour
% if SLs_num~=length(SLs)-1;  % Check if there are multiple contours by comparing the point count in the first contour with the total
%     G=fspecial('gaussian',[5 5],2);
%     OAbw=imfilter(OAbw,G,'same');  % Gaussian blur
% end
% close

% 
% % Recalculate the largest connected region after removing potentially isolated areas
% imlabel=bwlabel(OAbw);
% stats=regionprops(imlabel,'Area');
% area=cat(1,stats.Area);
% index=find(area==max(area));
% OAbw=ismember(imlabel,index);

land=Lbw';
land(1:22,:)=0;
delta_OAM=~OAbw';
 delta_OAM(1:22,:)=0;
wetfrac=(nnz(delta_OAM)-nnz(land))/nnz(delta_OAM);


% figure,imagesc(delta_OAM)
% figure,imagesc(land)

% delta_OAM 이랑 land 랑 다른부분이 channel

