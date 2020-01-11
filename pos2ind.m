function z_ref = pos2ind(z)
    polars = [2.1119,0.1436;
0.9826,0.1482;
2.0691,0.2842;
1.0263,0.2842;
1.5737,0.2373;
2.0833,0.5186;
1.0318,0.5186;
1.5737,0.5186;
1.5853,0.7529;
1.6319,0.9003];
x = polars(:,1).*cos(polars(:,2));
y = polars(:,1).*sin(polars(:,2));
z_in = [z(:,1)*cos(z(:,2)),z(:,1)*sin(z(:,2))];
    k = dsearchn([x,y],z_in);
    z_in
    if (~isnan(z(:,1)))
        z_ref = polars(k,:)
    else
        z_ref = z;
    end

end