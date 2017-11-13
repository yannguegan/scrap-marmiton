# coding: utf-8

import urllib2
import string
import json
import time
import re
import os
import unicodedata
from bs4 import BeautifulSoup
from pprint import pprint
from random import randint



def removeDiacritics(string):
	code = ''.join((c for c in unicodedata.normalize('NFD', string) if unicodedata.category(c) != 'Mn'))
	code = code.lower().replace(' ','').replace('\'','').replace('-','')
	return code


def getHTMLContent(url):
	try:
		page = urllib2.urlopen(url).read()
		soup = BeautifulSoup(page, 'html.parser')
	except urllib2.HTTPError, e:
		print e.code 
	except urllib2.URLError, e:
		print e.code
	return soup

def getNBpagesResult(ingredient):
	url = ingredient['url']
	ingredientPage = getHTMLContent(url)
	if ingredientPage.find(class_="ToCPagingContainer") is not None:
		pagesLink = ingredientPage.find(class_="ToCPagingContainer").find_all('a')
		nbPages = int(pagesLink[-1].get_text())
		end = False
		while end == False:
			url = ingredient['url'] + '&page=' + str(nbPages)
			ingredientPageLastResult = getHTMLContent(url)
			pagesLink = ingredientPageLastResult.find(class_="ToCPagingContainer").find_all('a')
			lastPage = int(pagesLink[-1].get_text())
			if lastPage > nbPages:
				nbPages = lastPage
			else:
				end = True
	else:
		nbPages = 1
	return nbPages

def getURLpagesResults(ingredient):
	urlPages = []
	for i in range(ingredient['nbPages']):
		urlPages.append(ingredient['url'] + '&page=' + str(i+1))
	return urlPages

def getRecipes(ingredient, allRecipes):
	recipes = []
	for url in ingredient['urlPages']:
		page = getHTMLContent(url)
		recipesLink = page.find(class_="m-lsting-recipe").find_all('a')
		for recipeLink in recipesLink:
			recipe = {
				'name': recipeLink.get_text().encode('utf-8'),
				'url': 'http://www.marmiton.org' + recipeLink['href'].encode('utf-8')
			}
			try:
				recipe['id'] = re.search('_(\d+)\.aspx', recipe['url']).group(1)
			except AttributeError:
				recipe['id'] = 'nc'
			recipes.append(recipe)
	for i,recipe in enumerate(recipes):
		if recipe['id'] != 'nc':
			try:
				recipes[i]['rate'] = allRecipes[recipe['id']]['rate']
				recipes[i]['nbComments'] = allRecipes[recipe['id']]['nbComments']
			except:
				recipes[i]['rate'] = 'nc'
				recipes[i]['nbComments'] = 'nc'
			if recipes[i]['nbComments'] != 'nc' and recipes[i]['rate'] != 'nc':
				recipes[i]['score'] = float(recipe['rate']) * float(recipe['nbComments'])
			else:
				recipes[i]['score'] = 0
		else:
			recipes[i]['rate'] = 'nc'
			recipes[i]['nbComments'] = 'nc'
			recipes[i]['score'] = 0
	return recipes

def getTopRecipes(ingredient):
	recipes = ingredient['recipes']
	recipes.sort(key= lambda x: x['score'], reverse=True)
	topRecipes = recipes[:20]
	return topRecipes

	

# Clear output
os.system('clear')

# Import recipes JSON file
try:
	recipesFile = open('recettes.json').read()
	recipes = json.loads(recipesFile)
except IOError:
	print('File recettes.json not found')

# Import ingredients JSON file
try:
	ingredientsFile = open ('ingredients.json').read()
	ingredients = json.loads(ingredientsFile)
except IOError:
	print('File ingredients.json not found')


forced = False
for i,ingredient in enumerate(ingredients):
	existing = False
	ingredients[i]['code'] = removeDiacritics(ingredient['name'])
	try:
		ingredientTopFile = open('top_recettes/' + ingredients[i]['code'].encode('utf-8') + '.json').read()
		existing = True
	except:
		print('File ' + ingredients[i]['code'].encode('utf-8') + '.json not found')
		pass
	if existing == False or forced == True:
		ingredients[i]['nbPages'] = getNBpagesResult(ingredient)
		ingredients[i]['urlPages'] = getURLpagesResults(ingredient)
		ingredients[i]['recipes'] = getRecipes(ingredient, recipes)
		ingredients[i]['topRecipes'] = getTopRecipes(ingredient)
		print('')
		print(ingredient['name'])
		for y, recipe in enumerate(ingredients[i]['topRecipes']):
			print(y+1, recipe['name'])
		fileRecipesJSON = open('top_recettes/' + ingredients[i]['code'] + '.json','w+')
		if len(ingredients[i]['topRecipes']) > 0:
			fileRecipesJSON.write(json.dumps(ingredients[i]['topRecipes'], indent=4))
	else:
		print('File ' + ingredients[i]['code'].encode('utf-8')  + '.json already created')

