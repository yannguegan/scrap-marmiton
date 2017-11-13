#!/bin/bash
"exec" "python" "$0"
import urllib2
import string
import json
import time
import re
from bs4 import BeautifulSoup
from pprint import pprint
from random import randint

def scrapRecipe( recipe ):
	"Get all the metadata of a recipe"
	recipe['error'] = False
	soupPageURL = recipe['url']
	time.sleep(randint(1,9)/ speed)

	print('')
	print('Scraping : ' + soupPageURL)
	
	# Check if recipe page is a video
	video = False
	if recipe['url'].find('/video/') != -1:
		video = True
		print('Hmm, this page seems to be a video')
		recipe['type'] = 'video'
	if not video:
		recipe['type'] = 'text'
		try:
			soupPage = urllib2.urlopen(soupPageURL)
			soup = BeautifulSoup(soupPage, 'html.parser')

			newDesign = False
			# Test if recipe page has new design
			if soup.find(id='m_content') is None:
				newDesign = True
			else: 
				print('Hmm, this page seems to have the old design')

			if newDesign:
				# Get recipe's name
				try:
					recipe['name'] = soup.h1.string.encode('utf-8')
				except AttributeError:
					recipe['error'] = True

				if recipe['error'] == False:
					print('Recette : ' + recipe['name'])
					# Get recipe's comments number
					recipeCommentsInfo = soup.find(class_='recipe-infos-users__value').string.encode('utf-8')
					try:
						recipe['nbComments'] = int(re.search('^(\d+)', recipeCommentsInfo).group(1))
					except AttributeError:
						# Nb of comments could not be parsed
						recipe['nbComments'] = 'nc'

					# Get recipe's rate
					recipeRateInfo = soup.find(class_='mrtn-stars').find_all(class_='icon-star-full-active')
					recipe['rate'] = len(recipeRateInfo)
					if recipe['rate'] == 0:
						recipe['rate'] = 'nc'

					# Get recipe's number fo share
					recipe['nbShares'] = int(soup.find(class_='recipe-infos-users__share').find(class_='recipe-infos-users__value').string)
			
					# Get recipe's number of bookmarks
					recipe['nbBookmarks'] = int(soup.find(class_='recipe-infos-users__notebook').find(class_='recipe-infos-users__value').string)

					# Get recipe's preparation time
					try:
						preparationTimeInfo = soup.find(class_='recipe-infos__total-time').find(class_='recipe-infos__total-time__value').string
						try:
							preparationTimeH = re.search('^(\d+)(h| h)', preparationTimeInfo).group(1)
						except AttributeError:
							# Nb of hours could not be parsed
							preparationTimeH = 0
						if preparationTimeH > 0:
							try:
								preparationTimeMn = re.search('h(\d+)', preparationTimeInfo).group(1)
							except AttributeError:
								preparationTimeMn = 0
						else:
							try:
								preparationTimeMn = re.search('(\d+)(min| min)', preparationTimeInfo).group(1)
							except AttributeError:
								preparationTimeMn = 0
						recipe['preparationTime'] = (int(preparationTimeH) * 60) + int(preparationTimeMn)		
					except TypeError:
						recipe['preparationTime'] = 'nc'	

					# Get recipe's quantity
					try:
						recipe['quantityType'] = soup.find(class_='recipe-infos__quantity').find(class_='recipe-infos__item-title').string.encode('utf-8')
						recipe['quantity'] = int(soup.find(class_='recipe-infos__quantity').find(class_='recipe-infos__quantity__value').string)
					except AttributeError:
						recipe['quantityType'] = 'nc'
						recipe['quantity'] = 'nc'

					# Get recipe's difficulty
					difficultyInfoClass = soup.find(class_='recipe-infos__level').find(class_='recipe-infos__level__container')['class']
					for el in difficultyInfoClass:
						try:
							recipe['difficulty'] = int(re.search('level-(\d)', el).group(1))
						except:
							pass

					# Get recipe's cost 
					costInfoClass = soup.find(class_='recipe-infos__budget').find(class_='recipe-infos__level__container')['class']
					for el in costInfoClass:
						try:
							recipe['cost'] = int(re.search('level-(\d)', el).group(1))
						except:
							pass

					# Get recipe's categories
					categoriesInfo = soup.find(class_='mrtn-tags-list').find_all(class_='mrtn-tag')
					categories = []
					for categoryInfo in categoriesInfo:
						category = categoryInfo.string.encode('utf-8')
						categories.append(category)
					recipe['categories'] = categories
		except urllib2.HTTPError, e:
			print('HTTPError = ' + str(e.code))
			recipe['error'] = True
		except urllib2.URLError, e:
			print('URLError = ' + str(e.reason))
			recipe['error'] = True
	return recipe		

# Scrap speed
speed = 15

# Variables used to store the scraped information
ingredients = []
ingredientCSVHead = '"nom","page","nb","note","temps","difficulte","cout","coms","persons","titre"\n'
recipes = {}
allrecipesID = []
allingredientsNames = []
recipeCSVHead = '"id","nom","cout","difficulte","note","temps","nbComs","type_quantite","quantite","categories","ingredient","url"\n'

# CSV files where the scraped data will be stored
fileIngredientsCSV = open('ingredients.csv','a+')
fileRecipesCSV = open('recettes.csv','a+')
JSONBuffer = 0

# Open JSON files with recipes and ingredients already scraped
try:
	recipesFile = open('recettes.json').read()
	recipes = json.loads(recipesFile)
	recipesCount = len(recipes)
	print(str(recipesCount) + ' recipes found in recettes.json file')
	for recipe in recipes:
		allrecipesID.append(recipe.encode('utf-8'))
	# print(allrecipesID)	
except IOError:
	print('File recettes.json not found')
	# fileRecipesCSV.write(recipeCSVHead)

try:
	ingredientsFile = open('ingredients.json').read()
	ingredients = json.loads(ingredientsFile)
	ingredientsCount = len(ingredients)
	print(str(ingredientsCount) + ' ingredients found in ingredients.json file')
	for ingredient in ingredients:
		allingredientsNames.append(ingredient['name'].encode('utf-8'))
	# print(allrecipesID)	
except IOError:
	print('File ingredients.json not found')
	fileIngredientsCSV.write(ingredientCSVHead)

# Prepare letter list
AZ = ['A','B','C','D','E']
for letter in reversed(AZ):
	print('')
	print('Letter ' + letter)
	time.sleep(randint(1,9)/ speed)
	# Get list of ingredients starting with same letter
	soupPageURL = 'http://www.marmiton.org/recettes/recettes-index.aspx'
	try:
		soupPage = urllib2.urlopen(soupPageURL + '?letter=' + letter)
		soup = BeautifulSoup(soupPage, 'html.parser')
		ingredientlinks = soup.find_all('a', attrs={'class':'item'})
		for ingredientlink in ingredientlinks:
			ingredient = {}
			ingredient['name'] = ingredientlink.get_text().encode('utf-8')
			if ingredient['name'] not in allingredientsNames:
				time.sleep(randint(1,9)/ speed)
				print(str(len(ingredientlinks)) + ' ingredients found')
				ingredient['url'] = 'http://www.marmiton.org' + ingredientlink['href'].encode('utf-8')
				print('')
				print('===')
				print('Ingredient : ' + ingredient['name'])

				# Variables used to summarize recipes info for an ingredeint
				ingredientRecipesNB = float(0)
				ingredientRatedRecipesNB = float(0)
				ingredientPersonsRecipesNB = float(0)
				ingredientTimeNB = float(0)
				ingredientRatesSum = float(0)
				ingredientDifficultySum = float(0)
				ingredientCostSum = float(0)
				ingredientComsSum = float(0)
				ingredientPersonsSum = float(0)
				ingredientTimeSum = float(0)
				ingredientIsInTitle = float(0)
				soupPageURL = ingredient['url']
				try:

					# Get number of recipes pages for the ingredient
					soupPage = urllib2.urlopen(soupPageURL)
					soup = BeautifulSoup(soupPage, 'html.parser')
					if soup.find(class_="ToCPagingContainer") is not None:
						pagesLink = soup.find(class_="ToCPagingContainer").find_all('a')
						nbPages = int(pagesLink[-1].get_text())
						end = False
						while end == False:
							soupPageURL = ingredient['url'] + '&page=' + str(nbPages)
							try: 
								soupPage = urllib2.urlopen(soupPageURL)
								soup = BeautifulSoup(soupPage, 'html.parser')
								pagesLink = soup.find(class_="ToCPagingContainer").find_all('a')
								lastPage = int(pagesLink[-1].get_text())
								if lastPage > nbPages:
									nbPages = lastPage
								else: end = True
							except urllib2.HTTPError, e:
								print('HTTPError = ' + str(e.code))
							except urllib2.URLError, e:
								print('URLError = ' + str(e.reason))
					else:
						nbPages = 1
					print('There are ' + str(nbPages) + ' result pages for this ingredient')
					# Ignore ingredients with too many results (useful for testing)
					if nbPages > 0:
						for i in range(nbPages):
							print('')
							print('Result page #' + str(i+1))
							time.sleep(randint(1,9)/ speed)
							soupPageURL = ingredient['url'] + '&page=' + str(i+1)
							try:

								# Scrap all result page for the ingredient
								soupPage = urllib2.urlopen(soupPageURL)
								soup = BeautifulSoup(soupPage, 'html.parser')
								recipesLinks = soup.find(class_="m-lsting-recipe").find_all('a')
								print('There are ' + str(len(recipesLinks)) + ' recipes on this page')

								# Get link and name of each recipe
								for recipeLink in recipesLinks:
									recipe = {}
									recipe['name'] = recipeLink.get_text().encode('utf-8')
									recipe['url'] = 'http://www.marmiton.org' + recipeLink['href'].encode('utf-8')
									# recipe['url'] = 'http://www.marmiton.org/recettes/recette_cake-pomme-noisettes_336137.aspx'
									try:
										recipe['id'] = re.search('_(\d+)\.aspx', recipe['url']).group(1)
									except AttributeError:
										# ID not found in URL
										recipe['id'] = 'nc'

									# Check if recipe is already in scraped data to avoid duplicates in recettes list
									if recipe['id'] not in allrecipesID:

										# Recipe is new, let's get all informations
										recipe = scrapRecipe(recipe)
										JSONBuffer += 1
										if JSONBuffer == 15:
											fileRecipesJSON = open('recettes.json','w+')
											fileRecipesJSON.write(json.dumps(recipes,indent=4))
											JSONBuffer = 0

										# Check if recipe was video
										if recipe['type'] != 'video':
											
											# Append recipe to all recipes list
											recipes[recipe['id']] = recipe

											if recipe['error'] == False:

												# Append recipe id to list of recipes id
												allrecipesID.append(recipe['id'])

												# Prepare new CSV line	
												recipe['categoriesAll'] = ''
												for category in recipe['categories']:
													recipe['categoriesAll'] += category
													if recipe['categories'].index(category) != len(recipe['categories']) - 1:
														recipe['categoriesAll'] += ' | '									
												recipeCSVRow = ('"' +
												  recipe['id'] + '","' + 
												  recipe['name'] + '","' +
												  str(recipe['cost']) + '","' +
												  str(recipe['difficulty']) + '","' +
												  str(recipe['rate']) + '","' +
												  str(recipe['preparationTime']) + '","' +
												  str(recipe['nbComments']) + '","' +
												  str(recipe['quantityType']) + '","' +
												  str(recipe['quantity']) + '","' +
												  recipe['categoriesAll'] + '","' +
												  ingredient['name'] + '","' + 
												  recipe['url'] + '"\n' )

												# Write new CSV line
												fileRecipesCSV.write(recipeCSVRow)
									else:
										print('Recipe "' + recipes[recipe['id']]['name'] + '" was already scraped' )

									# Calcultation for each ingredient
									ident = recipe['id']
									ingredientRecipesNB += 1
									try:
										# pprint(recipes[ident])
										if recipes[ident]['rate'] != 'nc':
											ingredientRatesSum += recipes[ident]['rate']
											ingredientRatedRecipesNB += 1
										if recipes[ident]['preparationTime'] != 'nc':
											ingredientTimeSum += recipes[ident]['preparationTime']
											ingredientTimeNB += 1
										ingredientDifficultySum += recipes[ident]['difficulty']
										ingredientCostSum += recipes[ident]['cost']
										ingredientComsSum += recipes[ident]['nbComments']
										personnesWording = [ 'personne', 'personnes' ]
										if recipes[ident]['quantityType'].lower() in personnesWording:
											ingredientPersonsSum += recipes[ident]['quantity']
											ingredientPersonsRecipesNB += 1
										try:
											if recipes[ident]['name'].lower().find(ingredient['name'].lower()) != -1:
												ingredientIsInTitle += 1
												# print('ingredient name found in recette name')
										except UnicodeDecodeError:
											pass
									except KeyError:
										pass
							except urllib2.HTTPError, e:
								print('HTTPError = ' + str(e.code))
							except urllib2.URLError, e:
								print('URLError = ' + str(e.reason))

						# All recipes for this ingredients are in data
						ingredient['nb'] = ingredientRecipesNB
						ingredients.append(ingredient)

						print('')	
						print('A total of ' + str(ingredient['nb']) + ' recipes were found for this ingredient')

						# Preparing new line in CSV file
						ingredientCSVRow = '"' + ingredient['name'] + '","' + ingredient['url'] + '","' + str(ingredient['nb']) + '"'	

						# Calcultation for each ingredient
						count = float(ingredientRecipesNB)

						if ingredientRatedRecipesNB > 0:
							ingredient['rate'] = round(ingredientRatesSum / ingredientRatedRecipesNB, 4)
						else:
							ingredient['rate'] = 'nc'
						ingredientCSVRow += ',"' + str(ingredient['rate']) + '"'
						print('Average rate : ' + str(ingredient['rate']))
						if ingredientTimeNB > 0:
							ingredient['time'] = round(ingredientTimeSum / ingredientTimeNB, 4)
						else:
							ingredient['time'] = 'nc'
						ingredientCSVRow += ',"' + str(ingredient['time']) + '"'
						print('Average time : ' + str(ingredient['time']))

						if count > 0:	
							ingredient['difficulty'] = round(ingredientDifficultySum / count, 4)
							print('Average difficulty : ' + str(ingredient['difficulty']))

							ingredient['cost'] = round(ingredientCostSum / count, 4)
							print('Average cost : ' + str(ingredient['cost']))				

							ingredient['coms'] = round(ingredientComsSum / count, 4)
							print('Average coms nb : ' + str(ingredient['coms']))

							ingredient['inTitle'] = round(ingredientIsInTitle / count * 100, 4)
							print('Average mentions in title : ' + str(ingredient['inTitle']))
						else:
							ingredient['difficulty'] = 'nc'
							ingredient['cost'] = 'nc'
							ingredient['coms'] = 'nc'
							ingredient['inTitle'] = 'nc'
						ingredientCSVRow += ',"' + str(ingredient['difficulty']) + '"'
						ingredientCSVRow += ',"' + str(ingredient['cost']) + '"'
						ingredientCSVRow += ',"' + str(ingredient['coms']) + '"'

						if ingredientPersonsRecipesNB > 0:
							ingredient['persons'] = round(ingredientPersonsSum / ingredientPersonsRecipesNB, 4)
						else:
							ingredient['persons'] = 'nc'
						ingredientCSVRow += ',"' + str(ingredient['persons']) + '"'
						print('Average persons nb : ' + str(ingredient['persons']))
						ingredientCSVRow += ',"' + str(ingredient['inTitle']) + '"\n'

						# Writing new line in CSV
						fileIngredientsCSV.write(ingredientCSVRow)

						# Write JSON file
						fileIngredientsJSON = open('ingredients.json','w+')
						fileIngredientsJSON.write(json.dumps(ingredients,indent=4))
				except urllib2.HTTPError, e:
					print('HTTPError = ' + str(e.code))
				except urllib2.URLError, e:
					print('URLError = ' + str(e.reason))
			else:
				print('Ingredient ' + ingredient['name'] + ' already in list')			
	except urllib2.HTTPError, e:
		print('HTTPError = ' + str(e.code))
	except urllib2.URLError, e:
		print('URLError = ' + str(e.reason))  