-- Bootstrapper.server
-- Brandon Wilcox
-- 11/30/2021

--[=[
	@class StackBootstrapper

	The StackBootstrapper is the single party responsible for re-organizing all the packages in the SuperStack
	packages folder to their specified locations at runtime.

	There is no API associated with this class as it is a server script that aggregates all the packages at runtime.

	* Written by Brandon Wilcox, DevTech
]=]
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerContainer = ServerScriptService:FindFirstChild("SuperStack", true)
local SharedContainer = ReplicatedStorage:FindFirstChild("SuperStack", true)

local SuperStack = require(SharedContainer:FindFirstChild("SuperStack"))

-- Localize the server package container.  This is where all server, client
-- and shared packages live before being reparented
local ServerPackageContainer = ServerContainer:FindFirstChild("Packages")

-- Create a container to store shared and client packages
-- Parent to ReplicatedStorage.SuperStack
local SharedPackageContainer = Instance.new("Folder")
SharedPackageContainer.Name = "Packages"
SharedPackageContainer.Parent = SharedContainer

-- Iterate through all namespaces in the ServerPackageContainer
for _, packageNamespace in pairs(ServerPackageContainer:GetChildren()) do

	-- Iterate through all packages in the server package container
	-- and move their modules to the proper locations
	for _, package in pairs(packageNamespace:GetChildren()) do
		package.Parent = ServerPackageContainer

		-- Some packages may be singleton packages, handle those before looking
		-- for multi-dimentional containers.  These packages default to the shared
		-- directoy
		if (package:IsA("ModuleScript")) then
			package.Parent = SharedPackageContainer

			continue
		end

		-- Look for multi-dimentional containers in package to move
		-- to proper location
		local serverPackage = package:FindFirstChild("Server")
		local clientPackage = package:FindFirstChild("Client")
		local sharedPackage = package:FindFirstChild("Shared")
		local children = package:GetChildren()

		-- Server modules can be parented directly to the package
		if (serverPackage) then
			for _, module in pairs(serverPackage:GetChildren()) do
				module.Parent = package
			end

			-- Destroy unused container
			serverPackage:Destroy()
		end

		-- Skip if package doesn't have client or shared parts
		if ((not clientPackage) and (not sharedPackage) and (#package:GetChildren() == 0)) then continue end

		-- Create a new container in shared
		local sharedContainer = Instance.new("Folder")
		sharedContainer.Name = package.Name
		sharedContainer.Parent = SharedPackageContainer

		-- If client package exists, move to client
		if (clientPackage) then
			for _, childModule in pairs(clientPackage:GetDescendants()) do
				if (not childModule:IsA("ModuleScript")) then continue end

				childModule.Parent = sharedContainer
			end

			clientPackage:Destroy()
		end

		-- If shared package exists, move to shared
		if (sharedPackage) then
			for _, childModule in pairs(sharedPackage:GetDescendants()) do
				if (not childModule:IsA("ModuleScript")) then continue end

				childModule.Parent = sharedContainer
			end

			sharedPackage:Destroy()
		end

		-- If package has any direct children, move them to shared
		for _, childModule in pairs(children) do
			if (not childModule:IsA("ModuleScript")) then continue end

			childModule.Parent = sharedContainer
		end
		
		-- Destroy package container if children have been moved
		if (#package:GetChildren() == 0) then
			package:Destroy()
		end
	end

	packageNamespace:Destroy()
end