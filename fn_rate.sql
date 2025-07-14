CREATE OR ALTER FUNCTION dbo.fn_rate
(
    @nper INT,
    @pmt FLOAT,
    @pv FLOAT
)
RETURNS FLOAT
AS
BEGIN
    DECLARE @rate FLOAT = 0.1;
    DECLARE @prevRate FLOAT;
    DECLARE @iter INT = 0;
    DECLARE @maxIter INT = 100;
    DECLARE @tol FLOAT = 1e-10;
    DECLARE @f FLOAT;
    DECLARE @df FLOAT;

    WHILE @iter < @maxIter
    BEGIN
        -- Avoid division by zero
        IF @rate = 0 RETURN NULL;

        -- Function value
        SET @f = @pmt * (1 - POWER(1 + @rate, -@nper)) / @rate + @pv;

        -- Derivative
        SET @df = (@pmt * (
                    (@nper * POWER(1 + @rate, -@nper - 1)) * @rate -
                    (1 - POWER(1 + @rate, -@nper))
                )) / POWER(@rate, 2);

        -- Prevent zero derivative
        IF ABS(@df) < 1e-12 BREAK;

        -- Newton-Raphson step
        SET @prevRate = @rate;
        SET @rate = @rate - @f / @df;

        IF ABS(@rate - @prevRate) < @tol BREAK;

        SET @iter += 1;
    END

    RETURN ROUND(@rate, 10);
END
