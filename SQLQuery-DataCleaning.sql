SELECT TOP (1000) [UniqueID ]
      ,[ParcelID]
      ,[LandUse]
      ,[PropertyAddress]
      ,[SaleDate]
      ,[SalePrice]
      ,[LegalReference]
      ,[SoldAsVacant]
      ,[OwnerName]
      ,[OwnerAddress]
      ,[Acreage]
      ,[TaxDistrict]
      ,[LandValue]
      ,[BuildingValue]
      ,[TotalValue]
      ,[YearBuilt]
      ,[Bedrooms]
      ,[FullBath]
      ,[HalfBath]
  FROM [PortfolioProjects].[dbo].[NashvilleHousing]


  -- Step 1: Standardize Date Format
-- Convert SaleDate to a standard date format
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate);

-- Optional: If SaleDateConverted was added successfully, drop the old SaleDate column and rename SaleDateConverted
-- ALTER TABLE NashvilleHousing DROP COLUMN SaleDate;
-- EXEC sp_rename 'NashvilleHousing.SaleDateConverted', 'SaleDate', 'COLUMN';

--------------------------------------------------------------------------------------------------------------------------

-- Step 2: Populate Missing Property Addresses using ParcelID
UPDATE a
SET a.PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProjects.dbo.NashvilleHousing a
JOIN PortfolioProjects.dbo.NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;

--------------------------------------------------------------------------------------------------------------------------

-- Step 3: Break Address into Individual Columns (Address, City, State)
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255), PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
    PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

-- Similar for OwnerAddress
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255), OwnerSplitCity NVARCHAR(255), OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

--------------------------------------------------------------------------------------------------------------------------

-- Step 4: Convert 'Y' and 'N' in SoldAsVacant to 'Yes' and 'No'
UPDATE NashvilleHousing
SET SoldAsVacant = CASE 
    WHEN SoldAsVacant = 'Y' THEN 'Yes'
    WHEN SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
END;

--------------------------------------------------------------------------------------------------------------------------

-- Step 5: Remove Duplicates based on specific columns
WITH RowNumCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
               ORDER BY UniqueID
           ) AS row_num
    FROM PortfolioProjects.dbo.NashvilleHousing
)
DELETE FROM RowNumCTE
WHERE row_num > 1;

--------------------------------------------------------------------------------------------------------------------------

-- Step 6: Handle Missing Values
-- If certain columns are critical, you can remove rows with missing values in those columns.
DELETE FROM PortfolioProjects.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL;

-- Alternatively, if you want to keep missing values, consider imputation or other methods.

--------------------------------------------------------------------------------------------------------------------------

-- Step 7: Drop Unused Columns (Optional)
ALTER TABLE PortfolioProjects.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate;


ALTER TABLE NashvilleHousing
ADD PropertyAddress NVARCHAR(255);

--------------------------------------------------------------------------------------------------------------------------

-- Step 8: Standardize and Clean Data Formats
-- Remove leading/trailing whitespace from important string columns
UPDATE NashvilleHousing
SET PropertyAddress = LTRIM(RTRIM(PropertyAddress)),
    SoldAsVacant = LTRIM(RTRIM(SoldAsVacant));

--------------------------------------------------------------------------------------------------------------------------

-- Optional: Check for Outliers in Numeric Columns (Optional)
SELECT *
FROM PortfolioProjects.dbo.NashvilleHousing
WHERE SalePrice > (SELECT AVG(SalePrice) + 3 * STDEV(SalePrice) FROM PortfolioProjects.dbo.NashvilleHousing);

